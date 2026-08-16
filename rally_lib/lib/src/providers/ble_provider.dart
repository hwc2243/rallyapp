import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/controller_command.dart';
import '../models/device_role.dart';
import '../models/live_telemetry.dart';
import '../services/ble_telemetry_service.dart';
import '../services/location_service.dart';
import 'bluetooth_controller_provider.dart';
import 'navigator_display_hold_provider.dart';
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

/// Settings a display should use. Driver and Navigator mirror the Controller.
final displaySettingsProvider = Provider<OdometerSettings>((ref) {
  final localSettings = ref.watch(settingsProvider);
  if (ref.watch(deviceRoleProvider) == DeviceRole.controller) {
    return localSettings;
  }
  final remoteSettings =
      ref.watch(bleTelemetryProvider).value?.controllerConfiguration;
  if (remoteSettings == null) return localSettings;
  return localSettings.copyWith(
    isMetric: remoteSettings.isMetric,
    isDecimalMinutes: remoteSettings.isDecimalMinutes,
    bumpAmount: remoteSettings.bumpAmount,
    bumpRequireDoubleTap: remoteSettings.bumpRequireDoubleTap,
    rallyTimeOffsetSeconds: remoteSettings.rallyTimeOffsetSeconds,
  );
});

/// Activates Controller-side publication at the configured packet rate.
final controllerBlePublisherProvider = Provider<void>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  if (ref.watch(deviceRoleProvider) != DeviceRole.controller) {
    return;
  }
  if (!ref.watch(bluetoothControllerEnabledProvider)) {
    unawaited(service.stopControllerAdvertising());
    return;
  }
  unawaited(service.startControllerAdvertising());
  ref.listen<LiveTelemetry>(liveTelemetryProvider, (_, telemetry) {
    service.publisher.publish(telemetry);
  }, fireImmediately: true);
});

/// Applies upstream Navigator packets through the normal Controller state
/// machines, exactly like a local Controller control interaction.
final controllerCommandDispatcherProvider = Provider<void>((ref) {
  final service = ref.watch(bleTelemetryServiceProvider);
  if (ref.watch(deviceRoleProvider) != DeviceRole.controller ||
      !ref.watch(bluetoothControllerEnabledProvider)) {
    return;
  }
  final subscription = service.commands.listen((command) {
    final odometer = ref.read(odometerProvider.notifier);
    switch (command.opcode) {
      case ControllerCommandOpcode.resetTotal:
        odometer.resetTotal();
      case ControllerCommandOpcode.resetInterval:
        odometer.resetInterval();
      case ControllerCommandOpcode.toggleHold:
        final navigatorHold = ref.read(navigatorDisplayHoldProvider.notifier);
        if (ref.read(navigatorDisplayHoldProvider).isHeld) {
          navigatorHold.release();
        } else {
          final telemetry = ref.read(liveTelemetryProvider);
          navigatorHold.hold(
            totalDistance: telemetry.totalDistance,
            timestamp: telemetry.timestamp,
          );
        }
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
        if (command.numericValue != null) {
          odometer.setTotalDistance(command.numericValue!);
        }
      case ControllerCommandOpcode.overrideIntervalMileage:
        if (command.numericValue != null) {
          odometer.setIntervalDistance(command.numericValue!);
        }
      case ControllerCommandOpcode.setCalibrationFactor:
        if (command.numericValue != null) {
          ref
              .read(settingsProvider.notifier)
              .setCalibrationFactor(command.numericValue!);
        }
      case ControllerCommandOpcode.setMetric:
        if (command.stringValue != null) {
          ref
              .read(settingsProvider.notifier)
              .setMetric(command.stringValue == 'true');
        }
      case ControllerCommandOpcode.setDecimalMinutes:
        if (command.stringValue != null) {
          ref
              .read(settingsProvider.notifier)
              .setDecimalMinutes(command.stringValue == 'true');
        }
      case ControllerCommandOpcode.setBumpAmount:
        if (command.numericValue != null) {
          ref
              .read(settingsProvider.notifier)
              .setBumpAmount(command.numericValue!);
        }
      case ControllerCommandOpcode.setBumpRequireDoubleTap:
        if (command.stringValue != null) {
          ref
              .read(settingsProvider.notifier)
              .setBumpRequireDoubleTap(command.stringValue == 'true');
        }
      case ControllerCommandOpcode.setRallyTimeOffset:
        if (command.numericValue != null) {
          ref.read(settingsProvider.notifier).setRallyTimeOffset(
                Duration(seconds: command.numericValue!.round()),
              );
        }
    }
  });
  ref.onDispose(subscription.cancel);
});
