import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_odometer/providers/odometer_provider.dart';
import 'package:rally_odometer/providers/settings_provider.dart';
import 'package:rally_odometer/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubLocationService extends LocationService {
  final StreamController<Position> _controller = StreamController<Position>.broadcast();

  @override
  Stream<Position> get positionStream => _controller.stream;

  @override
  Future<bool> handlePermission() async => true;

  @override
  double calculateFilteredDistance({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
  }) {
    return 0.0; // Isolate speed update
  }

  void emit(Position position) => _controller.add(position);
}

void main() {
  late StubLocationService stubLocationService;
  late SharedPreferences prefs;

  setUp(() async {
    stubLocationService = StubLocationService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('OdometerState initial speed is 0.0', () {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final state = container.read(odometerProvider);
    expect(state.currentSpeed, 0.0);
  });

  test('OdometerNotifier updates speed on position update', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(stubLocationService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Trigger lazy provider initialization
    container.read(odometerProvider);
    // Wait for _init() to finish its async permission check and subscribe
    await Future.delayed(const Duration(milliseconds: 100));

    final position = Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0,
      heading: 0,
      speed: 10.5, // 10.5 m/s
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    stubLocationService.emit(position);
    
    // Wait for stream event to be processed
    await Future.delayed(const Duration(milliseconds: 100));
    
    final state = container.read(odometerProvider);
    expect(state.currentSpeed, 10.5);
  });
}
