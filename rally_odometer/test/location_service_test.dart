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

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(distance, 0.0);
    });

    test('TRANSITION: Speed 0.8-2.5 m/s ignores small movements (<= 1.5m)', () {
      // 0.00001 degrees is approx 1.1 meters
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 1.0);
      final pos2 = createPosition(latitude: 0.00001, longitude: 0, speed: 1.0);

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(distance, 0.0);
    });

    test('TRANSITION: Speed 0.8-2.5 m/s counts large movements (> 1.5m)', () {
      // 0.0001 degrees is approx 11 meters
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 1.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 1.0);

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(distance, greaterThan(1.5));
    });

    test('ACTIVE: Speed > 2.5 m/s counts all movements', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.00001, longitude: 0, speed: 5.0);

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(distance, greaterThan(0.0));
      expect(distance, closeTo(1.11, 0.01)); // approx 1.1m
    });

    test('Accuracy Guard: ignores fixes with accuracy > 15m', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0, accuracy: 20.0);

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: factor,
      );

      expect(distance, 0.0);
    });

    test('Calibration Factor is applied correctly', () {
      final pos1 = createPosition(latitude: 0, longitude: 0, speed: 5.0);
      final pos2 = createPosition(latitude: 0.0001, longitude: 0, speed: 5.0);
      const customFactor = 1.1;

      final rawDistance = Geolocator.distanceBetween(0, 0, 0.0001, 0);
      final expectedDistance = rawDistance * customFactor;

      final distance = service.calculateFilteredDistance(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: customFactor,
      );

      expect(distance, closeTo(expectedDistance, 0.001));
    });
  });
}
