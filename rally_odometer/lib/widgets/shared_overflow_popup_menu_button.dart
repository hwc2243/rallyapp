import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:url_launcher/url_launcher.dart';

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
          case 'about':
            showDialog<void>(
              context: context,
              builder: (_) => _AboutDialog(
                isPro: ref.read(settingsProvider).precisionDriveAvailable,
              ),
            );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'details', child: Text('Details')),
        // Bluetooth is conditionally omitted by Settings on remote hardware.
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuItem(value: 'about', child: Text('About')),
      ],
    );
  }
}

class _AboutDialog extends StatefulWidget {
  const _AboutDialog({required this.isPro});

  final bool isPro;

  @override
  State<_AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<_AboutDialog> {
  late final ScrollController _scrollController = ScrollController();

  static final _supportUri = Uri(scheme: 'mailto', path: 'hwconnors@gmail.com');
  static final _privacyUri = Uri.parse(
    'https://rallymaster.connors.ddns.net/privacy',
  );

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.55;
    return AlertDialog(
      title: const Text('About'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360, maxHeight: maxContentHeight),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(
                  image: AssetImage('assets/rally_odometer_logo.png'),
                  width: 112,
                  height: 112,
                ),
                const SizedBox(height: 16),
                const Text('RallyMaster Odometer',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                const Text('Version 0.1.0'),
                const SizedBox(height: 12),
                Text(
                  widget.isPro
                      ? 'RallyMaster Odometer Pro'
                      : 'RallyMaster Odometer Free',
                ),
                if (widget.isPro) const Text('Includes PrecisionDrive Assist'),
                const SizedBox(height: 16),
                const Text('© 2026 H William Connors II'),
                TextButton(
                  onPressed: () => _open(_supportUri),
                  child: const Text('Contact Support'),
                ),
                TextButton(
                  onPressed: () => _open(_privacyUri),
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'RallyMaster Odometer',
                    applicationVersion: '0.1.0',
                  ),
                  child: const Text('Open-Source Licenses'),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
