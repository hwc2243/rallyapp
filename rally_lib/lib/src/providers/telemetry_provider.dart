import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/live_telemetry.dart';
import '../models/controller_configuration.dart';
import 'odometer_provider.dart';
import 'navigator_display_hold_provider.dart';
import 'settings_provider.dart';

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
    final settings = ref.read(settingsProvider);
    final navigatorHold = ref.read(navigatorDisplayHoldProvider);
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
      controllerConfiguration: ControllerConfiguration(
        isMetric: settings.isMetric,
        isDecimalMinutes: settings.isDecimalMinutes,
        rallyTimeOffsetSeconds: settings.rallyTimeOffsetSeconds,
        bumpAmount: settings.bumpAmount,
        bumpRequireDoubleTap: settings.bumpRequireDoubleTap,
      ),
      isNavigatorDisplayHeld: navigatorHold.isHeld,
      navigatorHeldTotalDistance: navigatorHold.heldTotalDistance,
      navigatorHeldTimestamp: navigatorHold.heldTimestamp,
      direction: odometer.direction.name,
    );
  }
}

final liveTelemetryProvider =
    NotifierProvider<LiveTelemetryNotifier, LiveTelemetry>(
  LiveTelemetryNotifier.new,
);
