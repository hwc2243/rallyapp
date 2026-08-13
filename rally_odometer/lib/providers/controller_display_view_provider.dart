import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

enum ControllerDisplayView { driver, navigator }

class ControllerDisplayViewNotifier extends Notifier<ControllerDisplayView> {
  static const _preferenceKey = 'controller_display_view';

  @override
  ControllerDisplayView build() {
    final storedValue = ref
        .watch(sharedPreferencesProvider)
        .getString(_preferenceKey);
    return ControllerDisplayView.values.firstWhere(
      (view) => view.name == storedValue,
      orElse: () => ControllerDisplayView.navigator,
    );
  }

  Future<void> setView(ControllerDisplayView view) async {
    state = view;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_preferenceKey, view.name);
  }
}

final controllerDisplayViewProvider =
    NotifierProvider<ControllerDisplayViewNotifier, ControllerDisplayView>(
      ControllerDisplayViewNotifier.new,
    );
