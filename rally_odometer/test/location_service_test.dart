import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_lib/rally_lib.dart';

void main() {
  group('LocationService GPS sync engine', () {
    Position createPosition({
      required double latitude,
      required double longitude,
      required DateTime timestamp,
      double speed = 0.0,
      double accuracy = 5.0,
    }) {
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        accuracy: accuracy,
        altitude: 0,
        heading: 0,
        speed: speed,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    test('rejects inaccurate fixes', () {
      final service = LocationService();
      final now = DateTime(2026, 4, 21, 12, 0, 0);

      final result = service.processGpsUpdate(
        lastPosition: null,
        currentPosition: createPosition(
          latitude: 0,
          longitude: 0,
          timestamp: now,
          accuracy: 20.0,
          speed: 5.0,
        ),
        calibrationFactor: 1.0,
        now: now,
      );

      expect(result.acceptedFix, false);
      expect(result.gpsDelta, 0.0);
    });

    test('uses moving average of last 3 valid speed samples', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);
      final p1 = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: base,
        speed: 3.0,
      );
      final p2 = createPosition(
        latitude: 0.0001,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 1)),
        speed: 6.0,
      );
      final p3 = createPosition(
        latitude: 0.0002,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 2)),
        speed: 9.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: p1,
        calibrationFactor: 1.0,
        now: base,
      );
      service.processGpsUpdate(
        lastPosition: p1,
        currentPosition: p2,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 1)),
      );
      final result = service.processGpsUpdate(
        lastPosition: p2,
        currentPosition: p3,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 2)),
      );

      expect(result.smoothedSpeed, closeTo(6.0, 1e-9));
    });

    test('requires three accurate clustered readings for calibration', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);

      expect(
        service.isPositionStable(
          createPosition(latitude: 42, longitude: -71, timestamp: base),
        ),
        false,
      );
      expect(
        service.isPositionStable(
          createPosition(
            latitude: 42.00001,
            longitude: -71,
            timestamp: base.add(const Duration(seconds: 1)),
          ),
        ),
        false,
      );
      expect(
        service.isPositionStable(
          createPosition(
            latitude: 42.00002,
            longitude: -71,
            timestamp: base.add(const Duration(seconds: 2)),
          ),
        ),
        true,
      );
    });

    test('uses windowed displacement for low-speed movement', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);
      final first = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: base,
        speed: 0.5,
      );
      final second = createPosition(
        latitude: 0.000003,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 1)),
        speed: 0.5,
      );
      final third = createPosition(
        latitude: 0.000006,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 2)),
        speed: 0.5,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: first,
        calibrationFactor: 1.0,
        now: base,
      );
      service.processGpsUpdate(
        lastPosition: first,
        currentPosition: second,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 1)),
      );
      final result = service.processGpsUpdate(
        lastPosition: second,
        currentPosition: third,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 2)),
      );

      expect(result.gpsDelta, greaterThan(0.0));
      expect(result.isStationaryLock, false);
    });

    test('park mode updates anchor and forces zero delta', () {
      final service = LocationService()..direction = OdometerDirection.park;
      final now = DateTime(2026, 4, 21, 12, 0, 0);
      final pos1 = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: now,
        speed: 4.0,
      );
      final pos2 = createPosition(
        latitude: 0.001,
        longitude: 0,
        timestamp: now.add(const Duration(seconds: 1)),
        speed: 4.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: pos1,
        calibrationFactor: 1.0,
        now: now,
      );
      final result = service.processGpsUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: 1.0,
        now: now.add(const Duration(seconds: 1)),
      );

      expect(result.acceptedFix, true);
      expect(result.anchorPosition, pos2);
      expect(result.gpsDelta, 0.0);
    });

    test('reverse mode returns a negative calibrated GPS delta', () {
      final service = LocationService()..direction = OdometerDirection.reverse;
      final now = DateTime(2026, 4, 21, 12, 0, 0);
      final pos1 = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: now,
        speed: 5.0,
      );
      final pos2 = createPosition(
        latitude: 0.0001,
        longitude: 0,
        timestamp: now.add(const Duration(seconds: 1)),
        speed: 5.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: pos1,
        calibrationFactor: 1.0,
        now: now,
      );
      final result = service.processGpsUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: 1.0,
        now: now.add(const Duration(seconds: 1)),
      );

      expect(result.gpsDelta, lessThan(0.0));
    });

    test('forward mode never returns a negative GPS delta', () {
      final service = LocationService();
      final now = DateTime(2026, 4, 21, 12, 0, 0);
      final first = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: now,
        speed: 5.0,
      );
      final second = createPosition(
        latitude: 0.0001,
        longitude: 0,
        timestamp: now.add(const Duration(seconds: 1)),
        speed: 5.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: first,
        calibrationFactor: -1.0,
        now: now,
      );
      final result = service.processGpsUpdate(
        lastPosition: first,
        currentPosition: second,
        calibrationFactor: -1.0,
        now: now.add(const Duration(seconds: 1)),
      );

      expect(result.gpsDelta, 0.0);
    });

    test('stationary lock engages after 3 seconds below threshold', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);
      final pos1 = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: base,
        speed: 0.5,
      );
      final pos2 = createPosition(
        latitude: 0.0001,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 4)),
        speed: 0.5,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: pos1,
        calibrationFactor: 1.0,
        now: base,
      );
      final result = service.processGpsUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 4)),
      );

      expect(result.isStationaryLock, true);
      expect(result.smoothedSpeed, 0.0);
      expect(result.gpsDelta, 0.0);
    });

    test('stationary lock refreshes its anchor for every GPS ping', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);
      final first = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: base,
        speed: 0.5,
      );
      final lockFix = createPosition(
        latitude: 0.0001,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 4)),
        speed: 0.5,
      );
      final driftFix = createPosition(
        latitude: 0.0002,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 5)),
        speed: 0.5,
        accuracy: 20.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: first,
        calibrationFactor: 1.0,
        now: base,
      );
      final locked = service.processGpsUpdate(
        lastPosition: first,
        currentPosition: lockFix,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 4)),
      );
      final drift = service.processGpsUpdate(
        lastPosition: locked.anchorPosition,
        currentPosition: driftFix,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 5)),
      );

      expect(locked.isStationaryLock, true);
      expect(drift.isStationaryLock, true);
      expect(drift.anchorPosition, driftFix);
      expect(drift.gpsDelta, 0.0);
    });

    test('hard reset anchor discards distance after a long GPS gap', () {
      final service = LocationService();
      final base = DateTime(2026, 4, 21, 12, 0, 0);
      final pos1 = createPosition(
        latitude: 0,
        longitude: 0,
        timestamp: base,
        speed: 5.0,
      );
      final pos2 = createPosition(
        latitude: 0.001,
        longitude: 0,
        timestamp: base.add(const Duration(seconds: 6)),
        speed: 5.0,
      );

      service.processGpsUpdate(
        lastPosition: null,
        currentPosition: pos1,
        calibrationFactor: 1.0,
        now: base,
      );
      final result = service.processGpsUpdate(
        lastPosition: pos1,
        currentPosition: pos2,
        calibrationFactor: 1.0,
        now: base.add(const Duration(seconds: 6)),
      );

      expect(result.hardResetAnchor, true);
      expect(result.anchorPosition, pos2);
      expect(result.gpsDelta, 0.0);
    });
  });
}
