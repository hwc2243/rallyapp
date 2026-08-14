import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

enum ControllerDisplayView { driver, navigator }

class ControllerDisplayViewNotifier extends Notifier<ControllerDisplayView> {
  static const _preferenceKey = 'controller_display_view';

  @override
  ControllerDisplayView build() {
    final storedValue =
        ref.watch(sharedPreferencesProvider).getString(_preferenceKey);
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

/// Local presentation choice for a remote Driver/Navigator device. This does
/// not change its BLE role or Controller pairing.
class RemoteDisplayViewNotifier extends Notifier<ControllerDisplayView> {
  static const _preferenceKey = 'remote_display_view';

  @override
  ControllerDisplayView build() {
    final storedValue =
        ref.watch(sharedPreferencesProvider).getString(_preferenceKey);
    if (storedValue != null) {
      return ControllerDisplayView.values.firstWhere(
        (view) => view.name == storedValue,
        orElse: () => _defaultView(),
      );
    }
    return _defaultView();
  }

  ControllerDisplayView _defaultView() =>
      ref.watch(deviceRoleProvider) == DeviceRole.driver
          ? ControllerDisplayView.driver
          : ControllerDisplayView.navigator;

  Future<void> setView(ControllerDisplayView view) async {
    state = view;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_preferenceKey, view.name);
  }
}

final remoteDisplayViewProvider =
    NotifierProvider<RemoteDisplayViewNotifier, ControllerDisplayView>(
  RemoteDisplayViewNotifier.new,
);
