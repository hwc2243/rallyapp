import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

class OdometerNotifier extends StateNotifier<OdometerState> {
  final LocationService _locationService;
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  OdometerNotifier(this._locationService, this._ref)
      : super(OdometerState(totalDistance: 0, intervalDistance: 0)) {
    _loadDistances();
    _init();
  }

  void _loadDistances() {
    final prefs = _ref.read(sharedPreferencesProvider);
    state = OdometerState(
      totalDistance: prefs.getDouble('totalDistance') ?? 0,
      intervalDistance: prefs.getDouble('intervalDistance') ?? 0,
      direction: OdometerDirection.values[prefs.getInt('odometerDirection') ?? 0],
    );
    _locationService.direction = state.direction;
  }

  void _saveDistances() {
    final prefs = _ref.read(sharedPreferencesProvider);
    prefs.setDouble('totalDistance', state.totalDistance);
    prefs.setDouble('intervalDistance', state.intervalDistance);
    prefs.setInt('odometerDirection', state.direction.index);
  }

  void _init() async {
    final hasPermission = await _locationService.handlePermission();
    if (hasPermission) {
      _positionSubscription = _locationService.positionStream.listen(_onPositionUpdate);
    }
  }

  void setDirection(OdometerDirection direction) {
    state = state.copyWith(direction: direction);
    _locationService.direction = direction;
    _saveDistances();
  }

  void _onPositionUpdate(Position position) {
    final factor = _ref.read(settingsProvider).calibrationFactor;
    
    final result = _locationService.processLocationUpdate(
      lastPosition: _lastPosition,
      currentPosition: position,
      calibrationFactor: factor,
    );

    state = state.copyWith(
      totalDistance: state.totalDistance + result.distance,
      intervalDistance: state.intervalDistance + result.distance,
      currentSpeed: result.displaySpeed,
      isStationaryLock: result.isStationaryLock,
      lastAccuracy: position.accuracy,
    );

    if (result.distance != 0) {
      _saveDistances();
    }
    
    // Always update last position if accuracy is good, to allow continuous tracking
    if (position.accuracy <= LocationService.maxAccuracyThreshold) {
      _lastPosition = position;
    }
  }

  void toggleHold() {
    if (state.isHeld) {
      state = state.copyWith(
        isHeld: false,
        frozenTotalDistance: null,
        frozenTime: null,
      );
    } else {
      state = state.copyWith(
        isHeld: true,
        frozenTotalDistance: state.totalDistance,
        frozenTime: DateTime.now(),
      );
    }
  }

  void resetTotal() {
    state = state.copyWith(
      totalDistance: 0,
      // If held, we should probably update the frozen mileage too if we reset
      frozenTotalDistance: state.isHeld ? 0 : null,
    );
    _saveDistances();
  }

  void resetInterval() {
    state = state.copyWith(intervalDistance: 0);
    _saveDistances();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final odometerProvider = StateNotifierProvider<OdometerNotifier, OdometerState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return OdometerNotifier(locationService, ref);
});

