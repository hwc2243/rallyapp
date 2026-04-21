import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdometerSettings {
  final bool isMetric;
  final bool isDecimalMinutes;
  final double calibrationFactor;
  final double bumpAmount;
  final bool bumpRequireDoubleTap;

  OdometerSettings({
    required this.isMetric,
    required this.isDecimalMinutes,
    required this.calibrationFactor,
    required this.bumpAmount,
    required this.bumpRequireDoubleTap,
  });

  OdometerSettings copyWith({
    bool? isMetric,
    bool? isDecimalMinutes,
    double? calibrationFactor,
    double? bumpAmount,
    bool? bumpRequireDoubleTap,
  }) {
    return OdometerSettings(
      isMetric: isMetric ?? this.isMetric,
      isDecimalMinutes: isDecimalMinutes ?? this.isDecimalMinutes,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      bumpAmount: bumpAmount ?? this.bumpAmount,
      bumpRequireDoubleTap:
          bumpRequireDoubleTap ?? this.bumpRequireDoubleTap,
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
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  void toggleMetric() {
    final toggledToMetric = !state.isMetric;
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
    state = state.copyWith(isDecimalMinutes: !state.isDecimalMinutes);
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
    state = state.copyWith(
      bumpRequireDoubleTap: !state.bumpRequireDoubleTap,
    );
    _prefs.setBool('bumpRequireDoubleTap', state.bumpRequireDoubleTap);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

final settingsProvider = NotifierProvider<SettingsNotifier, OdometerSettings>(() {
  return SettingsNotifier();
});
