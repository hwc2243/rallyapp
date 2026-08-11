import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_odometer/providers/odometer_provider.dart';
import 'package:rally_odometer/providers/settings_provider.dart';
import 'package:rally_odometer/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubLocationService extends LocationService {
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  double nextGpsDelta = 0.0;
  double nextSmoothedSpeed = 0.0;
  bool nextHardResetAnchor = false;
  bool nextAcceptedFix = true;
  bool nextStationaryLock = false;

  @override
  Stream<Position> get positionStream => _controller.stream;

  @override
  Future<bool> handlePermission() async => true;

  @override
  GpsSyncResult processGpsUpdate({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
    DateTime? now,
  }) {
    return GpsSyncResult(
      acceptedFix: nextAcceptedFix,
      hardResetAnchor: nextHardResetAnchor,
      anchorPosition: currentPosition,
      gpsDelta: direction == OdometerDirection.reverse
          ? -nextGpsDelta
          : nextGpsDelta,
      smoothedSpeed: nextSmoothedSpeed,
      isStationaryLock: nextStationaryLock,
    );
  }

  void emit(Position position) => _controller.add(position);
}

void main() {
  late StubLocationService stubLocationService;
  late SharedPreferences prefs;

  Position createPosition({
    double latitude = 0,
    double longitude = 0,
    double speed = 0,
    double accuracy = 5.0,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      heading: 0,
      speed: speed,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  setUp(() async {
    stubLocationService = StubLocationService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('OdometerState initial state is forward', () {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final state = container.read(odometerProvider);
    expect(state.currentSpeed, 0.0);
    expect(state.direction, OdometerDirection.forward);
    expect(state.isStationaryLock, false);
  });

  test(
    'SettingsNotifier persists bump amount and converts it on unit toggle',
    () {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(stubLocationService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(settingsProvider.notifier);
      notifier.setBumpAmount(0.010);
      expect(container.read(settingsProvider).bumpAmount, 0.010);
      expect(prefs.getDouble('bumpAmount'), 0.010);

      notifier.toggleMetric();

      final metricBump = container.read(settingsProvider).bumpAmount;
      expect(container.read(settingsProvider).isMetric, true);
      expect(metricBump, closeTo(0.01609344, 1e-9));
      expect(prefs.getDouble('bumpAmount'), closeTo(0.01609344, 1e-9));

      notifier.toggleMetric();

      expect(container.read(settingsProvider).isMetric, false);
      expect(container.read(settingsProvider).bumpAmount, closeTo(0.010, 1e-9));
    },
  );

  test('SettingsNotifier toggles persisted bump double-tap requirement', () {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final notifier = container.read(settingsProvider.notifier);

    expect(container.read(settingsProvider).bumpRequireDoubleTap, false);
    expect(prefs.getBool('bumpRequireDoubleTap'), isNull);

    notifier.toggleBumpRequireDoubleTap();

    expect(container.read(settingsProvider).bumpRequireDoubleTap, true);
    expect(prefs.getBool('bumpRequireDoubleTap'), true);

    notifier.toggleBumpRequireDoubleTap();

    expect(container.read(settingsProvider).bumpRequireDoubleTap, false);
    expect(prefs.getBool('bumpRequireDoubleTap'), false);
  });

  test('OdometerNotifier updates direction and persists it', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final notifier = container.read(odometerProvider.notifier);
    notifier.setDirection(OdometerDirection.reverse);

    expect(
      container.read(odometerProvider).direction,
      OdometerDirection.reverse,
    );
    expect(stubLocationService.direction, OdometerDirection.reverse);
    expect(prefs.getInt('odometerDirection'), OdometerDirection.reverse.index);
  });

  test('GPS soft sync aligns distances to ground truth', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    stubLocationService.nextGpsDelta = 10.0;
    stubLocationService.nextSmoothedSpeed = 0.0;

    container.read(odometerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 25));

    stubLocationService.emit(createPosition(speed: 10.0));
    await Future<void>.delayed(const Duration(milliseconds: 75));

    expect(container.read(odometerProvider).totalDistance, closeTo(10.0, 1e-9));
    expect(
      container.read(odometerProvider).intervalDistance,
      closeTo(10.0, 1e-9),
    );
  });

  test(
    'interpolation loop advances odometers at 20Hz from smoothed speed',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(stubLocationService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      stubLocationService.nextGpsDelta = 0.0;
      stubLocationService.nextSmoothedSpeed = 10.0;

      container.read(odometerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      stubLocationService.emit(createPosition(speed: 10.0));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(container.read(odometerProvider).totalDistance, greaterThan(0.0));
      expect(
        container.read(odometerProvider).totalDistance,
        closeTo(container.read(odometerProvider).intervalDistance, 1e-9),
      );
      expect(
        container.read(odometerProvider).currentSpeed,
        closeTo(10.0, 1e-9),
      );
    },
  );

  test(
    'park mode keeps anchor fresh while forcing interpolation delta to zero',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(stubLocationService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      container
          .read(odometerProvider.notifier)
          .setDirection(OdometerDirection.park);
      stubLocationService.nextGpsDelta = 0.0;
      stubLocationService.nextSmoothedSpeed = 12.0;

      container.read(odometerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      stubLocationService.emit(createPosition(speed: 12.0));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(
        container.read(odometerProvider).totalDistance,
        closeTo(0.0, 1e-9),
      );
      expect(
        container.read(odometerProvider).intervalDistance,
        closeTo(0.0, 1e-9),
      );
      expect(
        container.read(odometerProvider).currentSpeed,
        closeTo(12.0, 1e-9),
      );
    },
  );

  test('OdometerNotifier applyBump uses imperial display units', () {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    container.read(settingsProvider.notifier).setBumpAmount(0.010);
    container.read(odometerProvider.notifier).applyBump(true);

    expect(
      container.read(odometerProvider).totalDistance,
      closeTo(16.09344, 1e-9),
    );
    expect(
      container.read(odometerProvider).intervalDistance,
      closeTo(16.09344, 1e-9),
    );
    expect(prefs.getDouble('totalDistance'), closeTo(16.09344, 1e-9));
    expect(prefs.getDouble('intervalDistance'), closeTo(16.09344, 1e-9));
  });

  test('OdometerNotifier applyBump uses metric display units after toggle', () {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final settingsNotifier = container.read(settingsProvider.notifier);
    settingsNotifier.setBumpAmount(0.010);
    settingsNotifier.toggleMetric();

    container.read(odometerProvider.notifier).applyBump(true);

    expect(
      container.read(odometerProvider).totalDistance,
      closeTo(16.09344, 1e-9),
    );
    expect(
      container.read(odometerProvider).intervalDistance,
      closeTo(16.09344, 1e-9),
    );

    container.read(odometerProvider.notifier).applyBump(false);
    expect(container.read(odometerProvider).totalDistance, closeTo(0.0, 1e-9));
    expect(
      container.read(odometerProvider).intervalDistance,
      closeTo(0.0, 1e-9),
    );
  });

  test('persisted crash recovery state includes calibration factor', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    container.read(settingsProvider.notifier).setCalibrationFactor(1.2345);
    container.read(odometerProvider.notifier).setTotalDistance(42.0);
    container.read(odometerProvider.notifier).setIntervalDistance(21.0);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(prefs.getDouble('totalDistance'), closeTo(42.0, 1e-9));
    expect(prefs.getDouble('intervalDistance'), closeTo(21.0, 1e-9));
    expect(prefs.getDouble('calibrationFactor'), closeTo(1.2345, 1e-9));
  });
}
