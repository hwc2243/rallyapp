import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rallymaster_app/services/session_lock_controller.dart';

void main() {
  testWidgets('obscures immediately but allows a short background return', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 29, 12);
    final controller = SessionLockController(
      authenticate: () async => true,
      now: () => now,
    );
    addTearDown(controller.dispose);

    controller.activate();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(controller.isObscured, isTrue);

    now = now.add(const Duration(seconds: 30));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(controller.isLocked, isFalse);
    expect(controller.isObscured, isFalse);
  });

  testWidgets('requires biometrics after the background grace period', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 29, 12);
    final biometricResult = Completer<bool>();
    final controller = SessionLockController(
      authenticate: () => biometricResult.future,
      now: () => now,
    );
    addTearDown(controller.dispose);

    controller.activate();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(controller.isLocked, isTrue);
    expect(controller.isObscured, isTrue);
    expect(controller.isUnlocking, isTrue);

    biometricResult.complete(true);
    await tester.pump();

    expect(controller.isLocked, isFalse);
    expect(controller.isObscured, isFalse);
  });
}
