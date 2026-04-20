import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'settings_provider.dart';

class OdometerState {
  final double totalDistance; // in meters (raw GPS * factor)
  final double intervalDistance; // in meters (raw GPS * factor)
  final double currentSpeed; // in m/s
  final bool isHeld;
  final double? frozenTotalDistance;
  final DateTime? frozenTime;

  OdometerState({
    required this.totalDistance,
    required this.intervalDistance,
    this.currentSpeed = 0.0,
    this.isHeld = false,
    this.frozenTotalDistance,
    this.frozenTime,
  });

  OdometerState copyWith({
    double? totalDistance,
    double? intervalDistance,
    double? currentSpeed,
    bool? isHeld,
    double? frozenTotalDistance,
    DateTime? frozenTime,
  }) {
    return OdometerState(
      totalDistance: totalDistance ?? this.totalDistance,
      intervalDistance: intervalDistance ?? this.intervalDistance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      isHeld: isHeld ?? this.isHeld,
      frozenTotalDistance: frozenTotalDistance ?? this.frozenTotalDistance,
      frozenTime: frozenTime ?? this.frozenTime,
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
    );
  }

  void _saveDistances() {
    final prefs = _ref.read(sharedPreferencesProvider);
    prefs.setDouble('totalDistance', state.totalDistance);
    prefs.setDouble('intervalDistance', state.intervalDistance);
  }

  void _init() async {
    final hasPermission = await _locationService.handlePermission();
    if (hasPermission) {
      _positionSubscription = _locationService.positionStream.listen(_onPositionUpdate);
    }
  }

  void _onPositionUpdate(Position position) {
    final factor = _ref.read(settingsProvider).calibrationFactor;
    
    final adjustedDistance = _locationService.calculateFilteredDistance(
      lastPosition: _lastPosition,
      currentPosition: position,
      calibrationFactor: factor,
    );

    state = state.copyWith(
      totalDistance: state.totalDistance + adjustedDistance,
      intervalDistance: state.intervalDistance + adjustedDistance,
      currentSpeed: position.speed,
    );

    if (adjustedDistance > 0) {
      _saveDistances();
      _lastPosition = position;
    } else if (_lastPosition == null && position.accuracy <= LocationService.maxAccuracyThreshold) {
      // Initialize last position with the first accurate fix
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
