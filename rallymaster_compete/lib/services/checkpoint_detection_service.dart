import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:rally_lib/rally_lib.dart';

import '../models/checkpoint_crossing.dart';
import '../models/competition_checkpoint.dart';

/// Foreground-only checkpoint recognition used while scoring is under
/// development. It records a local crossing, but deliberately has no scoring
/// or result-submission behavior.
class CheckpointDetectionService {
  CheckpointDetectionService({
    required List<CompetitionCheckpoint> checkpoints,
    required this.onCrossing,
    required Iterable<CheckpointCrossing> existingCrossings,
    this.sensorFusion,
  }) : _checkpoints = checkpoints
           .where(
             (checkpoint) =>
                 checkpoint.latitude != null && checkpoint.longitude != null,
           )
           .toList(growable: false),
       _crossedCheckpointIds = {
         for (final crossing in existingCrossings) crossing.checkpointId,
       };

  static const acquisitionRadiusMeters = 150.0;
  static const finalInterceptToleranceMeters = 40.0;
  static const headingHalfConeDegrees = 60.0;

  final List<CompetitionCheckpoint> _checkpoints;
  final void Function(CheckpointCrossing crossing) onCrossing;
  final Set<int> _crossedCheckpointIds;
  final SensorFusionService? sensorFusion;
  final Map<int, _CheckpointCandidate> _candidates = {};
  StreamSubscription<Position>? _subscription;

  Future<void> start() async {
    await _ensureLocationAccess();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen(_onPosition);
  }

  Future<void> dispose() => _subscription?.cancel() ?? Future.value();

  void _onPosition(Position position) {
    sensorFusion?.updateGps(position);
    final processedPosition = _precisionDrivePosition(position);
    for (final checkpoint in _checkpoints) {
      if (_crossedCheckpointIds.contains(checkpoint.id)) continue;
      final distance = Geolocator.distanceBetween(
        processedPosition.latitude,
        processedPosition.longitude,
        checkpoint.latitude!,
        checkpoint.longitude!,
      );
      final candidate = _candidates[checkpoint.id];
      if (distance <= acquisitionRadiusMeters) {
        final activeCandidate = candidate ?? _CheckpointCandidate();
        _candidates[checkpoint.id] = activeCandidate;
        if (_headingMatches(checkpoint, processedPosition.heading)) {
          activeCandidate.consider(processedPosition, distance);
        }
        activeCandidate.record(processedPosition, distance);
      } else if (candidate != null) {
        _candidates.remove(checkpoint.id);
        _completeIfValid(checkpoint, candidate);
      }
    }
  }

  /// Replaces a degraded GPS sample with the bounded sensor prediction only
  /// after PrecisionDrive has completed calibration and elected to assist.
  Position _precisionDrivePosition(Position gpsPosition) {
    final activeSensorFusion = sensorFusion;
    if (activeSensorFusion == null || !activeSensorFusion.isAssisting) {
      return gpsPosition;
    }
    final estimate = activeSensorFusion.locationEstimate;
    if (estimate == null) return gpsPosition;
    return Position(
      latitude: estimate.latitude,
      longitude: estimate.longitude,
      timestamp: gpsPosition.timestamp,
      accuracy: estimate.accuracy,
      altitude: gpsPosition.altitude,
      altitudeAccuracy: gpsPosition.altitudeAccuracy,
      heading: estimate.heading,
      headingAccuracy: gpsPosition.headingAccuracy,
      speed: estimate.speed,
      speedAccuracy: gpsPosition.speedAccuracy,
      floor: gpsPosition.floor,
      isMocked: gpsPosition.isMocked,
      verticalSpeed: gpsPosition.verticalSpeed,
      verticalSpeedAccuracy: gpsPosition.verticalSpeedAccuracy,
    );
  }

  void _completeIfValid(
    CompetitionCheckpoint checkpoint,
    _CheckpointCandidate candidate,
  ) {
    final best = candidate.best;
    if (best == null || best.distanceMeters > finalInterceptToleranceMeters) {
      return;
    }
    _crossedCheckpointIds.add(checkpoint.id);
    onCrossing(
      CheckpointCrossing(
        checkpointId: checkpoint.id,
        occurredAt: best.position.timestamp.toLocal(),
        closestDistanceMeters: best.distanceMeters,
        accuracyMeters: best.position.accuracy,
        heading: best.position.heading,
        speed: best.position.speed,
        interceptLatitude: best.position.latitude,
        interceptLongitude: best.position.longitude,
        samples: List.unmodifiable(candidate.samples),
      ),
    );
  }

  static bool _headingMatches(
    CompetitionCheckpoint checkpoint,
    double heading,
  ) {
    final expectedHeading = checkpoint.heading;
    if (expectedHeading == null) return true;
    if (!heading.isFinite || heading < 0) return false;
    final difference = (heading - expectedHeading).abs() % 360;
    final smallestDifference = difference > 180 ? 360 - difference : difference;
    return smallestDifference <= headingHalfConeDegrees;
  }

  static Future<void> _ensureLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const CheckpointDetectionException(
        'Turn on Location Services to detect checkpoints.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const CheckpointDetectionException(
        'Location access is required to detect checkpoints.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const CheckpointDetectionException(
        'Location access is disabled. Enable it for RallyMaster Compete in Settings.',
      );
    }
  }
}

class CheckpointDetectionException implements Exception {
  const CheckpointDetectionException(this.message);
  final String message;
}

class _CheckpointCandidate {
  _PositionSample? best;
  final List<CheckpointTelemetrySample> samples = [];

  void record(Position position, double distanceMeters) {
    samples.add(
      CheckpointTelemetrySample(
        capturedAt: position.timestamp.toLocal(),
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
        accuracy: position.accuracy,
        distanceToCheckpointMeters: distanceMeters,
      ),
    );
  }

  void consider(Position position, double distanceMeters) {
    if (best == null || distanceMeters < best!.distanceMeters) {
      best = _PositionSample(position, distanceMeters);
    }
  }
}

class _PositionSample {
  const _PositionSample(this.position, this.distanceMeters);
  final Position position;
  final double distanceMeters;
}
