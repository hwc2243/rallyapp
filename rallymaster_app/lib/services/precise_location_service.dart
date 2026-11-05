import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Waits for a cluster of accurate GPS readings before recording a checkpoint.
class PreciseLocationService {
  static const _maximumAccuracyMeters = 10.0;
  static const _maximumClusterSpreadMeters = 8.0;
  static const _requiredSamples = 3;
  static const _maximumWait = Duration(seconds: 60);
  static const _sampleInterval = Duration(seconds: 2);

  Future<Position> obtain() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is required to record a checkpoint.',
      );
    }

    final samples = <Position>[];
    DateTime? lastTimestamp;
    final deadline = DateTime.now().add(_maximumWait);
    while (DateTime.now().isBefore(deadline)) {
      Position position;
      try {
        // A one-shot request is reliable even when a platform does not emit
        // stream updates while the vehicle is stopped.
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        continue;
      }

      if (lastTimestamp != null && !position.timestamp.isAfter(lastTimestamp)) {
        await Future<void>.delayed(_sampleInterval);
        continue;
      }
      lastTimestamp = position.timestamp;
      if (position.accuracy > _maximumAccuracyMeters) {
        await Future<void>.delayed(_sampleInterval);
        continue;
      }

      if (samples.isNotEmpty &&
          Geolocator.distanceBetween(
                samples.first.latitude,
                samples.first.longitude,
                position.latitude,
                position.longitude,
              ) >
              _maximumClusterSpreadMeters) {
        samples.clear();
      }
      samples.add(position);
      if (samples.length >= _requiredSamples) return samples.last;

      await Future<void>.delayed(_sampleInterval);
    }
    throw StateError('No precise location was available within 60 seconds.');
  }
}
