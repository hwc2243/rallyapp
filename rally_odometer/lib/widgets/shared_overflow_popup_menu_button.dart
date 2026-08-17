import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return PopupMenuButton<String>(
      icon: Icon(icon, color: Colors.white, size: 28),
      onSelected: (action) {
        switch (action) {
          case 'details':
            Navigator.pushNamed(context, '/details');
          case 'settings':
            Navigator.pushNamed(context, '/settings');
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'details', child: Text('Details')),
        // Bluetooth is conditionally omitted by Settings on remote hardware.
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
      ],
    );
  }
}
