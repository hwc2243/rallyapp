import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';
import 'settings_provider.dart';

class OdometerState {
  final double totalDistance;
  final double intervalDistance;
  final double currentSpeed;
  final double lastAccuracy;
  final bool isHeld;
  final double? frozenTotalDistance;
  final DateTime? frozenTime;
  final OdometerDirection direction;
  final bool isStationaryLock;

  OdometerState({
    required this.totalDistance,
    required this.intervalDistance,
    this.currentSpeed = 0.0,
    this.lastAccuracy = 0.0,
    this.isHeld = false,
    this.frozenTotalDistance,
    this.frozenTime,
    this.direction = OdometerDirection.forward,
    this.isStationaryLock = false,
  });

  OdometerState copyWith({
    double? totalDistance,
    double? intervalDistance,
    double? currentSpeed,
    double? lastAccuracy,
    bool? isHeld,
    double? frozenTotalDistance,
    DateTime? frozenTime,
    OdometerDirection? direction,
    bool? isStationaryLock,
  }) {
    return OdometerState(
      totalDistance: totalDistance ?? this.totalDistance,
      intervalDistance: intervalDistance ?? this.intervalDistance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
      isHeld: isHeld ?? this.isHeld,
      frozenTotalDistance: frozenTotalDistance ?? this.frozenTotalDistance,
      frozenTime: frozenTime ?? this.frozenTime,
      direction: direction ?? this.direction,
      isStationaryLock: isStationaryLock ?? this.isStationaryLock,
    );
  }
}

class OdometerNotifier extends Notifier<OdometerState> {
  static const double _metersPerKilometer = 1000.0;
  static const double _metersPerMile = 1609.344;
  static const Duration _interpolationPeriod = Duration(milliseconds: 50);
  static const Duration _persistencePeriod = Duration(seconds: 5);
  static const double _interpolationSeconds = 0.05;
  static const double _softSyncThresholdMeters = 2.0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _interpolationTimer;
  Timer? _persistenceTimer;
  Position? _lastPosition;
  DateTime? _lastGpsFixAt;
  double _gpsAnchoredTotalDistance = 0.0;
  double _gpsAnchoredIntervalDistance = 0.0;

  @override
  OdometerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final locationService = ref.watch(locationServiceProvider);

    final initialState = OdometerState(
      totalDistance: prefs.getDouble('totalDistance') ?? 0.0,
      intervalDistance: prefs.getDouble('intervalDistance') ?? 0.0,
      direction:
          OdometerDirection.values[prefs.getInt('odometerDirection') ?? 0],
    );

    _gpsAnchoredTotalDistance = initialState.totalDistance;
    _gpsAnchoredIntervalDistance = initialState.intervalDistance;

    locationService.direction = initialState.direction;
    _startInterpolationLoop();
    _startPersistenceLoop();
    _init(locationService);

    ref.onDispose(() {
      _positionSubscription?.cancel();
      _interpolationTimer?.cancel();
      _persistenceTimer?.cancel();
    });

    return initialState;
  }

  void _init(LocationService locationService) async {
    final hasPermission = await locationService.handlePermission();
    if (!hasPermission) {
      return;
    }

    _positionSubscription = locationService.positionStream.listen(
      _onPositionUpdate,
    );
  }

  void _startInterpolationLoop() {
    _interpolationTimer?.cancel();
    _interpolationTimer = Timer.periodic(_interpolationPeriod, (_) {
      final locationService = ref.read(locationServiceProvider);
      final settings = ref.read(settingsProvider);
      final now = DateTime.now();
      final hasFreshGps =
          _lastGpsFixAt != null &&
          now.difference(_lastGpsFixAt!).inSeconds <=
              LocationService.backgroundGapThresholdSeconds;
      final displaySpeed = hasFreshGps ? state.currentSpeed : 0.0;
      final delta = hasFreshGps
          ? displaySpeed *
                _interpolationSeconds *
                locationService.directionMultiplier *
                settings.calibrationFactor
          : 0.0;

      state = state.copyWith(
        totalDistance: state.totalDistance + delta,
        intervalDistance: state.intervalDistance + delta,
        currentSpeed: displaySpeed,
      );
    });
  }

  void _startPersistenceLoop() {
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer.periodic(_persistencePeriod, (_) {
      _persistState();
    });
  }

  void _persistState() {
    final prefs = ref.read(sharedPreferencesProvider);
    _persistDistances(prefs);
    final settings = ref.read(settingsProvider);
    prefs.setDouble('calibrationFactor', settings.calibrationFactor);
  }

  void _persistDistances(SharedPreferences prefs) {
    prefs.setDouble('totalDistance', state.totalDistance);
    prefs.setDouble('intervalDistance', state.intervalDistance);
    prefs.setInt('odometerDirection', state.direction.index);
  }

  void _syncGpsAnchors({double? totalDistance, double? intervalDistance}) {
    if (totalDistance != null) {
      _gpsAnchoredTotalDistance = totalDistance;
    }
    if (intervalDistance != null) {
      _gpsAnchoredIntervalDistance = intervalDistance;
    }
  }

  void _onPositionUpdate(Position position) {
    final settings = ref.read(settingsProvider);
    final result = ref
        .read(locationServiceProvider)
        .processGpsUpdate(
          lastPosition: _lastPosition,
          currentPosition: position,
          calibrationFactor: settings.calibrationFactor,
        );

    state = state.copyWith(
      currentSpeed: result.smoothedSpeed,
      isStationaryLock: result.isStationaryLock,
      lastAccuracy: position.accuracy,
    );

    if (!result.acceptedFix) {
      return;
    }

    _lastGpsFixAt = DateTime.now();
    _lastPosition = result.anchorPosition;
    _gpsAnchoredTotalDistance += result.gpsDelta;
    _gpsAnchoredIntervalDistance += result.gpsDelta;

    final totalDrift = (state.totalDistance - _gpsAnchoredTotalDistance).abs();
    final intervalDrift =
        (state.intervalDistance - _gpsAnchoredIntervalDistance).abs();

    if (result.hardResetAnchor ||
        totalDrift > _softSyncThresholdMeters ||
        intervalDrift > _softSyncThresholdMeters) {
      state = state.copyWith(
        totalDistance: _gpsAnchoredTotalDistance,
        intervalDistance: _gpsAnchoredIntervalDistance,
      );
      _persistState();
    }
  }

  void setDirection(OdometerDirection direction) {
    state = state.copyWith(direction: direction);
    ref.read(locationServiceProvider).direction = direction;
    _persistState();
  }

  void toggleHold() {
    if (state.isHeld) {
      state = state.copyWith(
        isHeld: false,
        frozenTotalDistance: null,
        frozenTime: null,
      );
      return;
    }

    state = state.copyWith(
      isHeld: true,
      frozenTotalDistance: state.totalDistance,
      frozenTime: DateTime.now(),
    );
  }

  void resetTotal() {
    state = state.copyWith(
      totalDistance: 0.0,
      frozenTotalDistance: state.isHeld ? 0.0 : null,
    );
    _syncGpsAnchors(totalDistance: 0.0);
    _persistState();
  }

  void setTotalDistance(double meters) {
    state = state.copyWith(
      totalDistance: meters,
      frozenTotalDistance: state.isHeld ? meters : null,
    );
    _syncGpsAnchors(totalDistance: meters);
    _persistState();
  }

  void resetInterval() {
    state = state.copyWith(intervalDistance: 0.0);
    _syncGpsAnchors(intervalDistance: 0.0);
    _persistState();
  }

  void setIntervalDistance(double meters) {
    state = state.copyWith(intervalDistance: meters);
    _syncGpsAnchors(intervalDistance: meters);
    _persistState();
  }

  void applyBump(bool isPositive) {
    final settings = ref.read(settingsProvider);
    final bumpMeters = settings.isMetric
        ? settings.bumpAmount * _metersPerKilometer
        : settings.bumpAmount * _metersPerMile;
    final signedBump = isPositive ? bumpMeters : -bumpMeters;
    final newTotalDistance = state.totalDistance + signedBump;
    final newIntervalDistance = state.intervalDistance + signedBump;

    state = state.copyWith(
      totalDistance: newTotalDistance,
      intervalDistance: newIntervalDistance,
      frozenTotalDistance: state.isHeld ? newTotalDistance : null,
    );
    _syncGpsAnchors(
      totalDistance: newTotalDistance,
      intervalDistance: newIntervalDistance,
    );
    _persistState();
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final odometerProvider = NotifierProvider<OdometerNotifier, OdometerState>(() {
  return OdometerNotifier();
});
