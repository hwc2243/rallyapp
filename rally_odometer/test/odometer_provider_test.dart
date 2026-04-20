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
}
