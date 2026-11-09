import 'package:material_ui/material_ui.dart';

import 'screens/find_rally_screen.dart';
import 'widgets/rallymaster_compete_about_dialog.dart';

void main() => runApp(const RallyMasterCompeteApp());

class RallyMasterCompeteApp extends StatelessWidget {
  const RallyMasterCompeteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RallyMaster Compete',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffff6b1a)),
      useMaterial3: true,
    ),
    home: const CompeteHomeScreen(),
  );
}

class CompeteHomeScreen extends StatelessWidget {
  const CompeteHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('RallyMaster Compete'),
      actions: [
        PopupMenuButton<_MenuAction>(
          tooltip: 'Menu',
          icon: const Icon(Icons.settings_outlined),
          onSelected: (action) {
            if (action == _MenuAction.about) {
              showDialog<void>(
                context: context,
                builder: (_) => const RallyMasterCompeteAboutDialog(),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: _MenuAction.about, child: Text('About')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/rallymaster_compete_about_logo.png'),
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 24),
              Text(
                'RallyMaster Compete',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Competitor scoring for your next rally.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Find an active rally near you to get started.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const FindRallyScreen(),
                  ),
                ),
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Find my rally'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _MenuAction { about }
