import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// The physical-mount validation state used by PrecisionDrive Assist.
enum PrecisionDriveOrientationStatus {
  idle,
  awaitingConfirmation,
  calibratingStationary,
  needsDriveForward,
  aligned,
}

/// How the phone is mounted in the vehicle for PrecisionDrive Assist.
enum PrecisionDriveMountOrientation { upright, flat }

/// The current result of checking that the phone is mounted flat and forward.
///
/// [arrowRotationRadians] rotates an up-facing UI arrow toward the direction
/// the phone's top needs to face. It is based on the difference between the
/// device magnetic heading and the most recent GPS course.
class PrecisionDriveOrientationState {
  const PrecisionDriveOrientationState({
    required this.status,
    this.arrowRotationRadians = 0.0,
  });

  final PrecisionDriveOrientationStatus status;
  final double arrowRotationRadians;

  bool get isMountedCorrectly =>
      status == PrecisionDriveOrientationStatus.aligned;

  bool get needsCalibration => !isMountedCorrectly;
}

/// A small, bounded extended Kalman filter for short GPS-quality outages.
///
/// The state is `[east, north, velocityEast, velocityNorth, heading]` in a
/// local tangent plane. Accelerometer and gyroscope samples are used for the
/// non-linear prediction step; the magnetometer corrects heading and GPS
/// corrects position/velocity whenever its reported accuracy is acceptable.
///
/// This is deliberately a *short-term* aid, not a replacement for GPS. Sensor
/// errors grow quickly, so assisted distance is available only while a recent
/// sensor sample is present and the latest GPS horizontal accuracy is > 30 m.
class SensorFusionService {
  static const double defaultAssistanceAccuracyThresholdMeters = 30.0;
  static const Duration _sensorFreshness = Duration(seconds: 1);
  static const double _maxPredictionStepSeconds = 0.1;
  static const double _maxAccelerationMetersPerSecondSquared = 8.0;

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<AccelerometerEvent>? _gravitySubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  bool _started = false;
  bool _enabled = true;
  PrecisionDriveMountOrientation _mountOrientation =
      PrecisionDriveMountOrientation.upright;
  DateTime? _stationaryCalibrationStartedAt;
  double _calibrationGravityX = 0.0;
  double _calibrationGravityY = 0.0;
  double _calibrationGravityZ = 0.0;
  int _calibrationGravitySamples = 0;
  double _calibrationGyroX = 0.0;
  double _calibrationGyroZ = 0.0;
  int _calibrationGyroSamples = 0;
  double _gyroBiasX = 0.0;
  double _gyroBiasZ = 0.0;
  double _assistanceAccuracyThresholdMeters =
      defaultAssistanceAccuracyThresholdMeters;
  double _latestGpsAccuracy = double.infinity;
  DateTime? _lastSensorAt;
  DateTime? _lastPredictionAt;

  // State vector.
  double _east = 0.0;
  double _north = 0.0;
  double _velocityEast = 0.0;
  double _velocityNorth = 0.0;
  double _headingRadians = 0.0;
  double _forwardAcceleration = 0.0;
  double _yawRate = 0.0;
  double? _magneticHeadingRadians;
  double? _gravityX;
  bool _hasState = false;

  // Diagonal covariance. The transition is non-linear because acceleration is
  // rotated by heading, making this an EKF rather than a simple smoother.
  double _positionVariance = 400.0;
  double _velocityVariance = 25.0;
  double _headingVariance = 1.0;
  double _pendingDistanceMeters = 0.0;
  bool _wasAssisting = false;
  final ValueNotifier<PrecisionDriveOrientationState> orientation =
      ValueNotifier(
    const PrecisionDriveOrientationState(
      status: PrecisionDriveOrientationStatus.idle,
    ),
  );

  void start() {
    if (_started) return;
    _started = true;
    try {
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        _onAccelerometer,
        onError: (_, __) {},
      );
      _gravitySubscription = accelerometerEventStream().listen(
        _onGravity,
        onError: (_, __) {},
      );
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        _onGyroscope,
        onError: (_, __) {},
      );
      _magnetometerSubscription = magnetometerEventStream().listen(
        _onMagnetometer,
        onError: (_, __) {},
      );
    } catch (_) {
      // Unit-test and unsupported-platform environments may not install a
      // platform sensor channel. GPS-only tracking remains fully functional.
      _accelerometerSubscription?.cancel();
      _gravitySubscription?.cancel();
      _gyroscopeSubscription?.cancel();
      _magnetometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _gravitySubscription = null;
      _gyroscopeSubscription = null;
      _magnetometerSubscription = null;
      _started = false;
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _setOrientation(const PrecisionDriveOrientationState(
        status: PrecisionDriveOrientationStatus.idle,
      ));
    }
    _refreshAssistance();
  }

  /// Opens the mount-confirmation step. This is intentionally called only at
  /// app startup or from the user-initiated Calibrate action.
  void requestCalibration() {
    if (!_enabled) return;
    _stationaryCalibrationStartedAt = null;
    _calibrationGravityX = 0.0;
    _calibrationGravityY = 0.0;
    _calibrationGravityZ = 0.0;
    _calibrationGravitySamples = 0;
    _calibrationGyroX = 0.0;
    _calibrationGyroZ = 0.0;
    _calibrationGyroSamples = 0;
    _setOrientation(const PrecisionDriveOrientationState(
      status: PrecisionDriveOrientationStatus.awaitingConfirmation,
    ));
  }

  void beginCalibration() {
    if (!_enabled) return;
    _stationaryCalibrationStartedAt = DateTime.now();
    _calibrationGravityX = 0.0;
    _calibrationGravityY = 0.0;
    _calibrationGravityZ = 0.0;
    _calibrationGravitySamples = 0;
    _calibrationGyroX = 0.0;
    _calibrationGyroZ = 0.0;
    _calibrationGyroSamples = 0;
    _setOrientation(const PrecisionDriveOrientationState(
      status: PrecisionDriveOrientationStatus.calibratingStationary,
    ));
  }

  void setAssistanceAccuracyThresholdMeters(double meters) {
    if (!meters.isFinite) return;
    _assistanceAccuracyThresholdMeters = meters.clamp(1.0, 200.0).toDouble();
    _refreshAssistance();
  }

  bool get isAssisting {
    _refreshAssistance();
    return _wasAssisting;
  }

  double get speedMetersPerSecond => math
      .sqrt(_velocityEast * _velocityEast + _velocityNorth * _velocityNorth);

  /// Supplies the GPS measurement for the EKF correction step.
  void updateGps(Position position, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    _predict(timestamp);
    _latestGpsAccuracy = position.accuracy;
    final gpsHeading = _gpsHeading(position);
    if (gpsHeading != null) {}
    if (orientation.value.status ==
            PrecisionDriveOrientationStatus.needsDriveForward &&
        gpsHeading != null &&
        _magneticHeadingRadians != null) {
      _headingRadians = gpsHeading;
      _setOrientation(const PrecisionDriveOrientationState(
        status: PrecisionDriveOrientationStatus.aligned,
      ));
    }

    if (!_hasState) {
      _hasState = true;
      _headingRadians = gpsHeading ?? _magneticHeadingRadians ?? 0.0;
      _velocityEast = position.speed * math.sin(_headingRadians);
      _velocityNorth = position.speed * math.cos(_headingRadians);
      _lastPredictionAt = timestamp;
      _refreshAssistance();
      return;
    }

    // GPS is a correction source only at <=30 m. Above that we retain the
    // prediction rather than allowing a low-quality coordinate jump to alter
    // the distance calculation.
    if (position.accuracy <= _assistanceAccuracyThresholdMeters) {
      final gpsEast = _longitudeToEast(position.longitude, position.latitude);
      final gpsNorth = _latitudeToNorth(position.latitude);
      final positionNoise =
          math.max(4.0, position.accuracy * position.accuracy);
      final positionGain =
          _positionVariance / (_positionVariance + positionNoise);
      _east += positionGain * (gpsEast - _east);
      _north += positionGain * (gpsNorth - _north);
      _positionVariance *= 1.0 - positionGain;

      if (position.speed.isFinite && position.speed >= 0.0) {
        final heading = _gpsHeading(position) ?? _headingRadians;
        final gpsVelocityEast = position.speed * math.sin(heading);
        final gpsVelocityNorth = position.speed * math.cos(heading);
        const velocityNoise = 4.0;
        final velocityGain =
            _velocityVariance / (_velocityVariance + velocityNoise);
        _velocityEast += velocityGain * (gpsVelocityEast - _velocityEast);
        _velocityNorth += velocityGain * (gpsVelocityNorth - _velocityNorth);
        _velocityVariance *= 1.0 - velocityGain;
      }
    }
    _refreshAssistance();
  }

  /// Returns newly predicted distance since the prior call.
  double consumePredictedDistanceMeters() {
    _refreshAssistance();
    if (!_wasAssisting) {
      _pendingDistanceMeters = 0.0;
      return 0.0;
    }
    final distance = _pendingDistanceMeters;
    _pendingDistanceMeters = 0.0;
    return distance;
  }

  void _onAccelerometer(UserAccelerometerEvent event) {
    // userAccelerometer excludes gravity, which prevents tilt/gravity from
    // becoming a false acceleration input. In the upright landscape profile
    // the screen faces the driver, making the phone's negative Z axis
    // vehicle-forward.
    final forwardAcceleration =
        _mountOrientation == PrecisionDriveMountOrientation.upright
            ? -event.z
            : event.y;
    _forwardAcceleration = forwardAcceleration
        .clamp(-_maxAccelerationMetersPerSecondSquared,
            _maxAccelerationMetersPerSecondSquared)
        .toDouble();
    _recordSensorSample();
  }

  void _onGravity(AccelerometerEvent event) {
    if (event.x.isFinite && event.y.isFinite && event.z.isFinite) {
      _gravityX = event.x;
    }
    _recordStationaryCalibration(event);
  }

  void _onGyroscope(GyroscopeEvent event) {
    if (orientation.value.status ==
        PrecisionDriveOrientationStatus.calibratingStationary) {
      _calibrationGyroX += event.x;
      _calibrationGyroZ += event.z;
      _calibrationGyroSamples++;
    }
    final yawRate = _mountOrientation == PrecisionDriveMountOrientation.upright
        ? _uprightLandscapeSign * (event.x - _gyroBiasX)
        : event.z - _gyroBiasZ;
    _yawRate = yawRate.clamp(-math.pi, math.pi).toDouble();
    _recordSensorSample();
  }

  void _onMagnetometer(MagnetometerEvent event) {
    // Map the phone axes to vehicle-forward for the selected mount. For an
    // upright landscape phone, X is vertical while -Z faces forward. Heading
    // is corrected gently so local magnetic disturbance cannot cause a sudden
    // distance jump.
    if (event.x.isFinite &&
        event.y.isFinite &&
        event.z.isFinite &&
        (event.x.abs() + event.y.abs() + event.z.abs()) > 0.001) {
      _magneticHeadingRadians = _normaliseAngle(
        _mountOrientation == PrecisionDriveMountOrientation.upright
            ? math.atan2(_uprightLandscapeSign * event.y, -event.z)
            : math.atan2(-event.x, event.y),
      );
    }
    _recordSensorSample();
  }

  void _recordSensorSample() {
    final now = DateTime.now();
    _predict(now);
    _lastSensorAt = now;
    _refreshAssistance();
  }

  void _predict(DateTime now) {
    final previous = _lastPredictionAt;
    _lastPredictionAt = now;
    if (!_hasState || previous == null) return;
    final elapsed = now.difference(previous).inMicroseconds / 1000000.0;
    if (elapsed <= 0.0) return;
    final dt = math.min(elapsed, _maxPredictionStepSeconds);
    final oldEast = _east;
    final oldNorth = _north;

    _headingRadians = _normaliseAngle(_headingRadians + _yawRate * dt);
    if (_magneticHeadingRadians != null) {
      const magneticVariance = 0.35;
      final gain = _headingVariance / (_headingVariance + magneticVariance);
      _headingRadians = _normaliseAngle(
        _headingRadians +
            gain * _angleDifference(_magneticHeadingRadians!, _headingRadians),
      );
      _headingVariance *= 1.0 - gain;
    }
    final accelerationEast = _forwardAcceleration * math.sin(_headingRadians);
    final accelerationNorth = _forwardAcceleration * math.cos(_headingRadians);
    _east += _velocityEast * dt + 0.5 * accelerationEast * dt * dt;
    _north += _velocityNorth * dt + 0.5 * accelerationNorth * dt * dt;
    _velocityEast += accelerationEast * dt;
    _velocityNorth += accelerationNorth * dt;

    // Process noise includes unmodelled vehicle acceleration and gyro drift.
    _positionVariance += _velocityVariance * dt * dt + 0.5;
    _velocityVariance += 1.5 * dt;
    _headingVariance += 0.02 * dt;

    if (_wasAssisting) {
      _pendingDistanceMeters += math.sqrt(
        math.pow(_east - oldEast, 2) + math.pow(_north - oldNorth, 2),
      );
    }
  }

  void _refreshAssistance() {
    final sensorIsFresh = _lastSensorAt != null &&
        DateTime.now().difference(_lastSensorAt!) <= _sensorFreshness;
    final shouldAssist = _enabled &&
        orientation.value.isMountedCorrectly &&
        _hasState &&
        sensorIsFresh &&
        _latestGpsAccuracy > _assistanceAccuracyThresholdMeters;
    if (shouldAssist != _wasAssisting) {
      _pendingDistanceMeters = 0.0;
      _wasAssisting = shouldAssist;
    }
  }

  void _recordStationaryCalibration(AccelerometerEvent event) {
    if (orientation.value.status !=
        PrecisionDriveOrientationStatus.calibratingStationary) {
      return;
    }
    _calibrationGravityX += event.x;
    _calibrationGravityY += event.y;
    _calibrationGravityZ += event.z;
    _calibrationGravitySamples++;
    final startedAt = _stationaryCalibrationStartedAt;
    if (startedAt == null ||
        DateTime.now().difference(startedAt) < const Duration(seconds: 2) ||
        _calibrationGravitySamples < 20) {
      return;
    }
    // The dominant gravity axis identifies the fixed mount. An X-dominant
    // phone is upright landscape; otherwise preserve flat top-forward mode.
    final x = _calibrationGravityX.abs();
    final y = _calibrationGravityY.abs();
    final z = _calibrationGravityZ.abs();
    _mountOrientation = x > y && x > z
        ? PrecisionDriveMountOrientation.upright
        : PrecisionDriveMountOrientation.flat;
    if (_calibrationGyroSamples > 0) {
      _gyroBiasX = _calibrationGyroX / _calibrationGyroSamples;
      _gyroBiasZ = _calibrationGyroZ / _calibrationGyroSamples;
    }
    _setOrientation(const PrecisionDriveOrientationState(
      status: PrecisionDriveOrientationStatus.needsDriveForward,
    ));
  }

  void _setOrientation(PrecisionDriveOrientationState next) {
    final current = orientation.value;
    if (current.status == next.status &&
        (current.arrowRotationRadians - next.arrowRotationRadians).abs() <
            0.01) {
      return;
    }
    orientation.value = next;
  }

  /// The phone X-axis direction that points upward. This lets the upright
  /// profile work whether the phone is mounted landscape-left or -right.
  double get _uprightLandscapeSign =>
      (_gravityX ?? 1.0).isNegative ? -1.0 : 1.0;

  // The EKF uses a local tangent plane. Absolute origin cancels because each
  // GPS correction is converted with the same projection.
  double _latitudeToNorth(double latitude) => latitude * 111132.92;
  double _longitudeToEast(double longitude, double latitude) =>
      longitude * 111319.49 * math.cos(latitude * math.pi / 180.0);

  double? _gpsHeading(Position position) => position.heading.isFinite &&
          position.heading >= 0.0 &&
          position.speed > 0.5
      ? position.heading * math.pi / 180.0
      : null;

  double _normaliseAngle(double angle) {
    final normalized = angle % (2.0 * math.pi);
    return normalized < 0.0 ? normalized + 2.0 * math.pi : normalized;
  }

  double _angleDifference(double target, double source) {
    var difference = _normaliseAngle(target) - _normaliseAngle(source);
    if (difference > math.pi) difference -= 2.0 * math.pi;
    if (difference < -math.pi) difference += 2.0 * math.pi;
    return difference;
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gravitySubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    orientation.dispose();
  }
}
