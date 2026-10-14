import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  static const double assistanceAccuracyThresholdMeters = 30.0;
  static const Duration _sensorFreshness = Duration(seconds: 1);
  static const double _maxPredictionStepSeconds = 0.1;
  static const double _maxAccelerationMetersPerSecondSquared = 8.0;

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  bool _started = false;
  bool _enabled = true;
  double _latestGpsAccuracy = double.infinity;
  DateTime? _lastSensorAt;
  DateTime? _lastPredictionAt;
  DateTime? _lastGpsAt;

  // State vector.
  double _east = 0.0;
  double _north = 0.0;
  double _velocityEast = 0.0;
  double _velocityNorth = 0.0;
  double _headingRadians = 0.0;
  double _forwardAcceleration = 0.0;
  double _yawRate = 0.0;
  double? _magneticHeadingRadians;
  bool _hasState = false;

  // Diagonal covariance. The transition is non-linear because acceleration is
  // rotated by heading, making this an EKF rather than a simple smoother.
  double _positionVariance = 400.0;
  double _velocityVariance = 25.0;
  double _headingVariance = 1.0;
  double _pendingDistanceMeters = 0.0;
  bool _wasAssisting = false;

  void start() {
    if (_started) return;
    _started = true;
    try {
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        _onAccelerometer,
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
      _gyroscopeSubscription?.cancel();
      _magnetometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _magnetometerSubscription = null;
      _started = false;
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
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
    _lastGpsAt = timestamp;

    if (!_hasState) {
      _hasState = true;
      _headingRadians = _gpsHeading(position) ?? _magneticHeadingRadians ?? 0.0;
      _velocityEast = position.speed * math.sin(_headingRadians);
      _velocityNorth = position.speed * math.cos(_headingRadians);
      _lastPredictionAt = timestamp;
      _refreshAssistance();
      return;
    }

    // GPS is a correction source only at <=30 m. Above that we retain the
    // prediction rather than allowing a low-quality coordinate jump to alter
    // the distance calculation.
    if (position.accuracy <= assistanceAccuracyThresholdMeters) {
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
    // The device should be mounted flat with its top facing vehicle-forward.
    // userAccelerometer excludes gravity, which prevents tilt/gravity from
    // becoming a false acceleration input.
    _forwardAcceleration = event.y
        .clamp(-_maxAccelerationMetersPerSecondSquared,
            _maxAccelerationMetersPerSecondSquared)
        .toDouble();
    _recordSensorSample();
  }

  void _onGyroscope(GyroscopeEvent event) {
    _yawRate = event.z.clamp(-math.pi, math.pi).toDouble();
    _recordSensorSample();
  }

  void _onMagnetometer(MagnetometerEvent event) {
    // A horizontal mount is assumed. Heading is corrected gently so local
    // magnetic disturbance cannot cause a sudden distance jump.
    if (event.x.isFinite &&
        event.y.isFinite &&
        (event.x.abs() + event.y.abs()) > 0.001) {
      _magneticHeadingRadians = _normaliseAngle(math.atan2(-event.x, event.y));
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
        _hasState &&
        sensorIsFresh &&
        _latestGpsAccuracy > assistanceAccuracyThresholdMeters;
    if (shouldAssist != _wasAssisting) {
      _pendingDistanceMeters = 0.0;
      _wasAssisting = shouldAssist;
    }
  }

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
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
  }
}
