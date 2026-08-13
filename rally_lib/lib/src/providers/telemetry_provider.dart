import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/live_telemetry.dart';
import 'odometer_provider.dart';

/// Publishes a fresh telemetry snapshot at the 20 Hz master refresh rate.
///
/// This loop is deliberately independent from distance accumulation: location
/// details and its timestamp continue to refresh while the odometer is parked
/// or its total display is held.
class LiveTelemetryNotifier extends Notifier<LiveTelemetry> {
  static const _refreshPeriod = Duration(milliseconds: 50);
  Timer? _refreshTimer;

  @override
  LiveTelemetry build() {
    final initial = _snapshot(DateTime.now());
    _refreshTimer = Timer.periodic(_refreshPeriod, (_) {
      state = _snapshot(DateTime.now());
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    return initial;
  }

  LiveTelemetry _snapshot(DateTime timestamp) {
    final odometer = ref.read(odometerProvider);
    return LiveTelemetry(
      totalDistance: odometer.totalDistance,
      intervalDistance: odometer.intervalDistance,
      timestamp: timestamp,
      speed: odometer.currentSpeed,
      bearing: odometer.lastValidBearing,
      latitude: odometer.latitude,
      longitude: odometer.longitude,
      gpsAccuracy: odometer.lastAccuracy,
      isDisplayHeld: odometer.isHeld,
    );
  }
}

final liveTelemetryProvider =
    NotifierProvider<LiveTelemetryNotifier, LiveTelemetry>(
      LiveTelemetryNotifier.new,
    );
