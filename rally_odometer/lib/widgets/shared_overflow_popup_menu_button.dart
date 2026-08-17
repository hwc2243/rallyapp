import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/controller_display_view_provider.dart';

/// Shared role-aware overflow menu for the Driver and Navigator dashboards.
class SharedOverflowPopupMenuButton extends ConsumerWidget {
  const SharedOverflowPopupMenuButton({
    super.key,
    required this.isControllerEngine,
    this.icon = Icons.menu,
  });

  final bool isControllerEngine;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRemote = !isControllerEngine;
    final displayView = isControllerEngine
        ? ref.watch(controllerDisplayViewProvider)
        : ref.watch(remoteDisplayViewProvider);
    return PopupMenuButton<String>(
      icon: Icon(icon, color: Colors.white, size: 28),
      onSelected: (action) {
        switch (action) {
          case 'details':
            Navigator.pushNamed(context, '/details');
          case 'toggle-view':
            final nextView = displayView == ControllerDisplayView.driver
                ? ControllerDisplayView.navigator
                : ControllerDisplayView.driver;
            if (isControllerEngine) {
              ref
                  .read(controllerDisplayViewProvider.notifier)
                  .setView(nextView);
            } else {
              ref.read(remoteDisplayViewProvider.notifier).setView(nextView);
            }
          case 'settings':
            Navigator.pushNamed(context, '/settings');
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'details', child: Text('Details')),
        if (isControllerEngine || isRemote)
          PopupMenuItem(
            value: 'toggle-view',
            child: Text(
              displayView == ControllerDisplayView.driver
                  ? 'Navigator View'
                  : 'Driver View',
            ),
          ),
        // Both Controller and remote displays use the same Settings sections.
        // Bluetooth is conditionally omitted by Settings on remote hardware.
        if (isControllerEngine || isRemote)
          const PopupMenuItem(value: 'settings', child: Text('Settings')),
      ],
    );
  }
}
