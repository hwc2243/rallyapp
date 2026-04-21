import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_odometer/providers/odometer_provider.dart';
import 'package:rally_odometer/providers/settings_provider.dart';
import 'package:rally_odometer/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubLocationService extends LocationService {
  final StreamController<Position> _controller = StreamController<Position>.broadcast();

  @override
  Stream<Position> get positionStream => _controller.stream;

  @override
  Future<bool> handlePermission() async => true;

  @override
  LocationUpdateResult processLocationUpdate({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
  }) {
    if (direction == OdometerDirection.park) {
      return LocationUpdateResult(distance: 0.0, displaySpeed: 0.0, isStationaryLock: false);
    }
    const dist = 10.0;
    final distance = direction == OdometerDirection.reverse ? -dist : dist;
    return LocationUpdateResult(
      distance: distance,
      displaySpeed: currentPosition.speed,
      isStationaryLock: false,
    );
  }

  void emit(Position position) => _controller.add(position);
}

void main() {
  late StubLocationService stubLocationService;
  late SharedPreferences prefs;

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

  test('SettingsNotifier persists bump amount and converts it on unit toggle', () {
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
  });

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

    expect(container.read(odometerProvider).direction, OdometerDirection.reverse);
    expect(stubLocationService.direction, OdometerDirection.reverse);
    expect(prefs.getInt('odometerDirection'), OdometerDirection.reverse.index);
  });

  test('OdometerNotifier updates distance based on direction', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    container.read(odometerProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    final pos = Position(
      latitude: 0, longitude: 0, timestamp: DateTime.now(),
      accuracy: 5.0, altitude: 0, heading: 0, speed: 10.0,
      speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
    );

    // Initial 10m forward (Stub returns 10m)
    stubLocationService.emit(pos);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(odometerProvider).totalDistance, 10.0);

    // Change to Reverse
    container.read(odometerProvider.notifier).setDirection(OdometerDirection.reverse);
    stubLocationService.emit(pos);
    await Future.delayed(const Duration(milliseconds: 100));
    // Stub returns -10m in reverse
    expect(container.read(odometerProvider).totalDistance, 0.0);
  });

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
    expect(container.read(odometerProvider).intervalDistance, closeTo(0.0, 1e-9));
  });
}
