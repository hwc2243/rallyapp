import 'package:flutter/material.dart';

import '../services/session_lock_controller.dart';

class SessionLockOverlay extends StatelessWidget {
  const SessionLockOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  final SessionLockController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) => Stack(
      fit: StackFit.expand,
      children: [child!, if (controller.isObscured) _buildLockScreen(context)],
    ),
  );

  Widget _buildLockScreen(BuildContext context) => ColoredBox(
    color: const Color(0xFF071523),
    child: SafeArea(
      child: Center(
        child: controller.isLocked
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'RallyMaster is locked',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Authenticate to continue your rally session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: controller.isUnlocking
                          ? null
                          : controller.unlock,
                      icon: controller.isUnlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.face),
                      label: Text(
                        controller.isUnlocking
                            ? 'Authenticating…'
                            : 'Unlock with Face ID',
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}
