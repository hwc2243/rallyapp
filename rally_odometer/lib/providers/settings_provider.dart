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

class SettingsNotifier extends Notifier<OdometerSettings> {
  @override
  OdometerSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OdometerSettings(
      isMetric: prefs.getBool('isMetric') ?? false,
      isDecimalMinutes: prefs.getBool('isDecimalMinutes') ?? false,
      calibrationFactor: prefs.getDouble('calibrationFactor') ?? 1.00000,
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  void toggleMetric() {
    state = state.copyWith(isMetric: !state.isMetric);
    _prefs.setBool('isMetric', state.isMetric);
  }

  void toggleDecimalMinutes() {
    state = state.copyWith(isDecimalMinutes: !state.isDecimalMinutes);
    _prefs.setBool('isDecimalMinutes', state.isDecimalMinutes);
  }

  void setCalibrationFactor(double factor) {
    state = state.copyWith(calibrationFactor: factor);
    _prefs.setDouble('calibrationFactor', factor);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

final settingsProvider = NotifierProvider<SettingsNotifier, OdometerSettings>(() {
  return SettingsNotifier();
});
