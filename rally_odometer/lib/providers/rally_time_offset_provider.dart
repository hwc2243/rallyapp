import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

const _rallyTimeOffsetPreferenceKey = 'rally_time_offset_seconds';

/// Stores the difference between official rally time and device time.
class RallyTimeOffsetNotifier extends Notifier<Duration> {
  @override
  Duration build() {
    final seconds = ref
        .watch(sharedPreferencesProvider)
        .getInt(_rallyTimeOffsetPreferenceKey);
    return Duration(seconds: seconds ?? 0);
  }

  Future<void> setOffset(Duration offset) async {
    state = offset;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_rallyTimeOffsetPreferenceKey, offset.inSeconds);
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
  final timeDelta = ref.watch(rallyTimeOffsetProvider);
  final isDecimalMinutes = ref.watch(settingsProvider).isDecimalMinutes;
  yield DateTime.now().add(timeDelta);
  yield* Stream<DateTime>.periodic(
    isDecimalMinutes
        ? const Duration(milliseconds: 100)
        : const Duration(seconds: 1),
    (_) => DateTime.now().add(timeDelta),
  );
});
