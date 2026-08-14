import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdometerSettings {
  final bool isMetric;
  final bool isDecimalMinutes;
  final double calibrationFactor;
  final double bumpAmount;
  final bool bumpRequireDoubleTap;
  final int rallyTimeOffsetSeconds;

  OdometerSettings({
    required this.isMetric,
    required this.isDecimalMinutes,
    required this.calibrationFactor,
    required this.bumpAmount,
    required this.bumpRequireDoubleTap,
    required this.rallyTimeOffsetSeconds,
  });

  OdometerSettings copyWith({
    bool? isMetric,
    bool? isDecimalMinutes,
    double? calibrationFactor,
    double? bumpAmount,
    bool? bumpRequireDoubleTap,
    int? rallyTimeOffsetSeconds,
  }) {
    return OdometerSettings(
      isMetric: isMetric ?? this.isMetric,
      isDecimalMinutes: isDecimalMinutes ?? this.isDecimalMinutes,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      bumpAmount: bumpAmount ?? this.bumpAmount,
      bumpRequireDoubleTap: bumpRequireDoubleTap ?? this.bumpRequireDoubleTap,
      rallyTimeOffsetSeconds:
          rallyTimeOffsetSeconds ?? this.rallyTimeOffsetSeconds,
    );
  }
}

class SettingsNotifier extends Notifier<OdometerSettings> {
  @override
  OdometerSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OdometerSettings(
      isMetric: prefs.getBool('isMetric') ?? false,
      isDecimalMinutes: prefs.getBool('isDecimalMinutes') ?? false,
      calibrationFactor: prefs.getDouble('calibrationFactor') ?? 1.00000,
      bumpAmount: prefs.getDouble('bumpAmount') ?? 0.010,
      bumpRequireDoubleTap: prefs.getBool('bumpRequireDoubleTap') ?? false,
      rallyTimeOffsetSeconds: prefs.getInt('rallyTimeOffsetSeconds') ?? 0,
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  void toggleMetric() {
    setMetric(!state.isMetric);
  }

  void setMetric(bool isMetric) {
    if (state.isMetric == isMetric) return;
    final toggledToMetric = isMetric;
    final convertedBumpAmount = toggledToMetric
        ? state.bumpAmount * 1.609344
        : state.bumpAmount / 1.609344;
    state = state.copyWith(
      isMetric: toggledToMetric,
      bumpAmount: convertedBumpAmount,
    );
    _prefs.setBool('isMetric', state.isMetric);
    _prefs.setDouble('bumpAmount', state.bumpAmount);
  }

  void toggleDecimalMinutes() {
    setDecimalMinutes(!state.isDecimalMinutes);
  }

  void setDecimalMinutes(bool isDecimalMinutes) {
    state = state.copyWith(isDecimalMinutes: isDecimalMinutes);
    _prefs.setBool('isDecimalMinutes', state.isDecimalMinutes);
  }

  void setCalibrationFactor(double factor) {
    state = state.copyWith(calibrationFactor: factor);
    _prefs.setDouble('calibrationFactor', factor);
  }

  void setBumpAmount(double amount) {
    state = state.copyWith(bumpAmount: amount);
    _prefs.setDouble('bumpAmount', amount);
  }

  void toggleBumpRequireDoubleTap() {
    setBumpRequireDoubleTap(!state.bumpRequireDoubleTap);
  }

  void setBumpRequireDoubleTap(bool value) {
    state = state.copyWith(
      bumpRequireDoubleTap: value,
    );
    _prefs.setBool('bumpRequireDoubleTap', state.bumpRequireDoubleTap);
  }

  void setRallyTimeOffset(Duration offset) {
    state = state.copyWith(rallyTimeOffsetSeconds: offset.inSeconds);
    _prefs.setInt('rallyTimeOffsetSeconds', state.rallyTimeOffsetSeconds);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, OdometerSettings>(() {
  return SettingsNotifier();
});
