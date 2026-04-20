import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_odometer/services/location_service.dart';

void main() {
  group('LocationService Speed-Sense Filter', () {
    final service = LocationService();
    const factor = 1.0;

    Position createPosition({
      required double latitude,
      required double longitude,
      double speed = 0.0,
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

    test('STATIONARY: Speed < 0.8 m/s ignores movement', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 0.5);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0.0001, speed: 0.5);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, 0.0);
    });

    test('TRANSITION: Speed 0.8-2.5 m/s ignores small movements (<= 1.5m)', () {
      // 0.00001 degrees is approx 1.1 meters
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 1.0);
      final pos2 = createPosition(latitude: 0.00001, longitude: 0, speed: 1.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, 0.0);
    });

    test('TRANSITION: Speed 0.8-2.5 m/s counts large movements (> 1.5m)', () {
      // 0.0001 degrees is approx 11 meters
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 1.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 1.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, greaterThan(1.5));
    });

    test('ACTIVE: Speed > 2.5 m/s counts all movements', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.00001, longitude: 0, speed: 5.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, greaterThan(0.0));
      expect(result.distance, closeTo(1.11, 0.01)); // approx 1.1m
    });

    test('Accuracy Guard: ignores fixes with accuracy > 15m', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0, accuracy: 20.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, 0.0);
    });

    test('Calibration Factor is applied correctly', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0);
      const customFactor = 1.1;

      final rawDistance = Geolocator.distanceBetween(0, 0, 0.0001, 0);
      final expectedDistance = rawDistance * customFactor;

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: customFactor,
      );

      expect(result.distance, closeTo(expectedDistance, 0.001));
    });

    test('PARK: ignores all movement', () {
      service.direction = OdometerDirection.park;
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, 0.0);
      service.direction = OdometerDirection.forward; // Reset
    });

    test('REVERSE: subtracts distance', () {
      service.direction = OdometerDirection.reverse;
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0);

      final result = service.processLocationUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(result.distance, lessThan(0.0));
      expect(result.distance.abs(), greaterThan(1.5));
      service.direction = OdometerDirection.forward; // Reset
    });

    test('Stationary Lock: Speed < 0.8 m/s for 3 seconds sets isStationaryLock and zeroes speed', () async {
      final s = LocationService();
      final pos = createPosition(latitude: 0, longitude: 0, speed: 0.5);
      
      // We can't easily fake time without a clock, but we can wait in the test.
      // 0s
      s.processLocationUpdate(lastPosition: null, currentPosition: pos, calibrationFactor: 1.0);
      expect(s.isStationaryLock, false);

      await Future.delayed(Duration(seconds: 4));
      
      // > 3s
      final result = s.processLocationUpdate(lastPosition: pos, currentPosition: pos, calibrationFactor: 1.0);
      expect(s.isStationaryLock, true);
      expect(result.isStationaryLock, true);
      expect(result.displaySpeed, 0.0);
    });

    test('Stationary Lock: Unlock when speed > 1.2 m/s', () async {
      final s = LocationService();
      s.isStationaryLock = true;
      
      final pos = createPosition(latitude: 0, longitude: 0, speed: 1.3);
      final result = s.processLocationUpdate(lastPosition: null, currentPosition: pos, calibrationFactor: 1.0);
      
      expect(s.isStationaryLock, false);
      expect(result.isStationaryLock, false);
      expect(result.displaySpeed, 1.3);
    });

    test('Background Jump: > 5s gap discards first coordinate', () async {
      final s = LocationService();
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      s.processLocationUpdate(lastPosition: null, currentPosition: pos1, calibrationFactor: 1.0);
      
      await Future.delayed(Duration(seconds: 6));
      
      final pos2 = createPosition(latitude: 0.0001, longitude: 0.0001, speed: 5.0);
      final result = s.processLocationUpdate(lastPosition: pos1, currentPosition: pos2, calibrationFactor: 1.0);
      
      expect(result.distance, 0.0);
      
      // Second coordinate after gap should work
      final pos3 = createPosition(latitude: 0.0002, longitude: 0.0002, speed: 5.0);
      final result2 = s.processLocationUpdate(lastPosition: pos2, currentPosition: pos3, calibrationFactor: 1.0);
      expect(result2.distance, greaterThan(0.0));
    });
  });
}
