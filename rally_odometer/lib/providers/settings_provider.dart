import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdometerSettings {
  final bool isMetric;
  final bool isDecimalMinutes;
  final double calibrationFactor;

  OdometerSettings({
    required this.isMetric,
    required this.isDecimalMinutes,
    required this.calibrationFactor,
  });

  OdometerSettings copyWith({
    bool? isMetric,
    bool? isDecimalMinutes,
    double? calibrationFactor,
  }) {
    return OdometerSettings(
      isMetric: isMetric ?? this.isMetric,
      isDecimalMinutes: isDecimalMinutes ?? this.isDecimalMinutes,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
    );
  }
}

class SettingsNotifier extends StateNotifier<OdometerSettings> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
      : super(OdometerSettings(
          isMetric: prefs.getBool('isMetric') ?? false,
          isDecimalMinutes: prefs.getBool('isDecimalMinutes') ?? false,
          calibrationFactor: prefs.getDouble('calibrationFactor') ?? 1.00000,
        ));

  void toggleMetric() {
    state = state.copyWith(isMetric: !state.isMetric);
    prefs.setBool('isMetric', state.isMetric);
  }

  void toggleDecimalMinutes() {
    state = state.copyWith(isDecimalMinutes: !state.isDecimalMinutes);
    prefs.setBool('isDecimalMinutes', state.isDecimalMinutes);
  }

  void setCalibrationFactor(double factor) {
    state = state.copyWith(calibrationFactor: factor);
    prefs.setDouble('calibrationFactor', factor);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, OdometerSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
