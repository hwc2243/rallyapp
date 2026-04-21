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

class OdometerNotifier extends Notifier<OdometerState> {
  static const double _metersPerKilometer = 1000.0;
  static const double _metersPerMile = 1609.344;

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  @override
  OdometerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final locationService = ref.watch(locationServiceProvider);

    final initialState = OdometerState(
      totalDistance: prefs.getDouble('totalDistance') ?? 0,
      intervalDistance: prefs.getDouble('intervalDistance') ?? 0,
      direction: OdometerDirection.values[prefs.getInt('odometerDirection') ?? 0],
    );

    locationService.direction = initialState.direction;
    _init(locationService);

    ref.onDispose(() {
      _positionSubscription?.cancel();
    });

    return initialState;
  }

  void _init(LocationService locationService) async {
    final hasPermission = await locationService.handlePermission();
    if (hasPermission) {
      _positionSubscription = locationService.positionStream.listen(_onPositionUpdate);
    }
  }

  void _saveDistances() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setDouble('totalDistance', state.totalDistance);
    prefs.setDouble('intervalDistance', state.intervalDistance);
    prefs.setInt('odometerDirection', state.direction.index);
  }

  void setDirection(OdometerDirection direction) {
    state = state.copyWith(direction: direction);
    ref.read(locationServiceProvider).direction = direction;
    _saveDistances();
  }

  void _onPositionUpdate(Position position) {
    final factor = ref.read(settingsProvider).calibrationFactor;
    
    final result = ref.read(locationServiceProvider).processLocationUpdate(
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
      frozenTotalDistance: state.isHeld ? 0 : null,
    );
    _saveDistances();
  }

  void setTotalDistance(double meters) {
    state = state.copyWith(
      totalDistance: meters,
      frozenTotalDistance: state.isHeld ? meters : null,
    );
    _saveDistances();
  }

  void resetInterval() {
    state = state.copyWith(intervalDistance: 0);
    _saveDistances();
  }

  void setIntervalDistance(double meters) {
    state = state.copyWith(intervalDistance: meters);
    _saveDistances();
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
    _saveDistances();
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final odometerProvider = NotifierProvider<OdometerNotifier, OdometerState>(() {
  return OdometerNotifier();
});
