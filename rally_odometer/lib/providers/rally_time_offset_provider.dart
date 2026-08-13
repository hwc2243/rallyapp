import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

/// Stores the difference between official rally time and device time.
class RallyTimeOffsetNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration(
        seconds: ref.watch(settingsProvider).rallyTimeOffsetSeconds,
      );

  Future<void> setOffset(Duration offset) async {
    ref.read(settingsProvider.notifier).setRallyTimeOffset(offset);
    state = offset;
  }

  Future<void> reset() => setOffset(Duration.zero);
}

final rallyTimeOffsetProvider =
    NotifierProvider<RallyTimeOffsetNotifier, Duration>(
  RallyTimeOffsetNotifier.new,
);

/// Formats the shared rally time using the selected display preference.
String formatRallyTime(DateTime time, bool isDecimalMinutes) {
  if (!isDecimalMinutes) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  final hundredths =
      ((time.second + time.millisecond / 1000) / 60 * 100).floor();
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}.'
      '${hundredths.toString().padLeft(2, '0')}';
}

/// Emits adjusted rally time at the precision needed by the clock preference.
final currentTimeProvider = StreamProvider<DateTime>((ref) async* {
  final displaySettings = ref.watch(displaySettingsProvider);
  final timeDelta = Duration(seconds: displaySettings.rallyTimeOffsetSeconds);
  final isDecimalMinutes = displaySettings.isDecimalMinutes;
  final isRemoteDisplay =
      ref.watch(deviceRoleProvider) != DeviceRole.controller;
  final telemetry =
      isRemoteDisplay ? ref.watch(bleTelemetryProvider).value : null;

  DateTime rallyTimeNow() {
    final controllerTimestamp = telemetry?.timestamp;
    final receivedAt = telemetry?.receivedAt;
    if (controllerTimestamp != null && receivedAt != null) {
      // Continue from the Controller's clock after the most recent packet;
      // this removes the remote device's own wall-clock skew.
      return controllerTimestamp
          .add(timeDelta)
          .add(DateTime.now().difference(receivedAt));
    }
    return DateTime.now().add(timeDelta);
  }

  yield rallyTimeNow();
  yield* Stream<DateTime>.periodic(
    isDecimalMinutes
        ? const Duration(milliseconds: 100)
        : const Duration(seconds: 1),
    (_) => rallyTimeNow(),
  );
});
