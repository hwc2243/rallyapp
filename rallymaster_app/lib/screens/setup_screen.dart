import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';

/// Temporary final step. This will hold the remaining rally setup later.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, required this.session, required this.rally});

  final AppSession session;
  final RallyDto rally;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rally setup')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selected organization',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              session.organization.name ?? 'Unnamed organization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Selected rally',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              rally.name ?? 'Unnamed rally',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    ),
  );
}
