import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RallyMasterAboutDialog extends StatefulWidget {
  const RallyMasterAboutDialog({super.key});

  @override
  State<RallyMasterAboutDialog> createState() => _RallyMasterAboutDialogState();
}

class _RallyMasterAboutDialogState extends State<RallyMasterAboutDialog> {
  final _scrollController = ScrollController();
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _packageInfo,
    builder: (context, snapshot) {
      final version = snapshot.data?.version ?? '…';
      return AlertDialog(
        title: const Text('About'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * .55,
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Image(
                    image: AssetImage('assets/rallymaster_about_logo.png'),
                    width: 112,
                    height: 112,
                  ),
                  const SizedBox(height: 16),
                  const Text('RallyMaster', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('Version $version'),
                  const SizedBox(height: 16),
                  const Text('© 2026 H William Connors II'),
                  TextButton(
                    onPressed: () => _open('mailto:hwconnors@gmail.com'),
                    child: const Text('Contact Support'),
                  ),
                  TextButton(
                    onPressed: () =>
                        _open('https://rallymaster.connors.ddns.net/privacy'),
                    child: const Text('Privacy Policy'),
                  ),
                  TextButton(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: 'RallyMaster',
                      applicationVersion: version,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );

  Future<void> _open(String value) =>
      launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
