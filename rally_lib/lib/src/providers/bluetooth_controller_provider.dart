import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

/// Persists whether this GPS-equipped Controller is advertising over BLE.
class BluetoothControllerEnabledNotifier extends Notifier<bool> {
  static const _preferenceKey = 'bluetooth_controller_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_preferenceKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_preferenceKey, enabled);
  }
}

final bluetoothControllerEnabledProvider =
    NotifierProvider<BluetoothControllerEnabledNotifier, bool>(
  BluetoothControllerEnabledNotifier.new,
);
