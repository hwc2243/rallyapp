import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/controller_command.dart';
import '../models/device_role.dart';
import '../models/live_telemetry.dart';
import '../services/ble_telemetry_service.dart';
import '../services/location_service.dart';
import 'odometer_provider.dart';
import 'settings_provider.dart';
import 'telemetry_provider.dart';

final bleTelemetryServiceProvider = Provider<BleTelemetryService>((ref) {
  final service = BleTelemetryService(ref.watch(sharedPreferencesProvider));
  ref.onDispose(service.dispose);
  return service;
});

class DeviceRoleNotifier extends Notifier<DeviceRole> {
  @override
  DeviceRole build() => ref.watch(bleTelemetryServiceProvider).role;

  Future<void> setRole(DeviceRole value) async {
    await ref.read(bleTelemetryServiceProvider).setRole(value);
    state = value;
  }
}

final deviceRoleProvider = NotifierProvider<DeviceRoleNotifier, DeviceRole>(
  DeviceRoleNotifier.new,
);

/// Remote Controller telemetry for Driver and Navigator dashboards.
final bleTelemetryProvider = StreamProvider<LiveTelemetry>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  unawaited(service.reconnect());
  return service.telemetry;
});

final bleConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  unawaited(service.reconnect());
  return service.connectionState;
});

/// Activates Controller-side publication at the configured packet rate.
final controllerBlePublisherProvider = Provider<void>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  if (ref.watch(deviceRoleProvider) != DeviceRole.controller) return;
  unawaited(service.startControllerAdvertising());
  ref.listen<LiveTelemetry>(liveTelemetryProvider, (_, telemetry) {
    service.publisher.publish(telemetry);
  }, fireImmediately: true);
});

/// Applies upstream Navigator packets through the normal Controller state
/// machines, exactly like a local Controller control interaction.
final controllerCommandDispatcherProvider = Provider<void>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  if (ref.watch(deviceRoleProvider) != DeviceRole.controller) return;
  final subscription = service.commands.listen((command) {
    final odometer = ref.read(odometerProvider.notifier);
    switch (command.opcode) {
      case ControllerCommandOpcode.resetTotal:
        odometer.resetTotal();
      case ControllerCommandOpcode.resetInterval:
        odometer.resetInterval();
      case ControllerCommandOpcode.toggleHold:
        odometer.toggleHold();
      case ControllerCommandOpcode.bumpPlus:
        odometer.applyBump(true);
      case ControllerCommandOpcode.bumpMinus:
        odometer.applyBump(false);
      case ControllerCommandOpcode.setFprState:
        final value = command.stringValue;
        if (value != null) {
          odometer.setDirection(OdometerDirection.values.firstWhere(
            (direction) => direction.name == value,
          ));
        }
      case ControllerCommandOpcode.overrideMileage:
        if (command.numericValue != null) odometer.setTotalDistance(command.numericValue!);
      case ControllerCommandOpcode.setCalibrationFactor:
        if (command.numericValue != null) {
          ref.read(settingsProvider.notifier).setCalibrationFactor(command.numericValue!);
        }
    }
  });
  ref.onDispose(subscription.cancel);
});
