import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/organization_dto.dart';
import '../models/rally_dto.dart';
import '../models/rally_setup_selection.dart';
import '../models/user_dto.dart';
import 'rally_selection_screen.dart';

class OrganizationSelectionScreen extends StatefulWidget {
  const OrganizationSelectionScreen({
    super.key,
    required this.user,
    required this.organizations,
    required this.accessToken,
  });

  final UserDto user;
  final List<OrganizationDto> organizations;
  final Future<String> Function() accessToken;

  @override
  State<OrganizationSelectionScreen> createState() =>
      _OrganizationSelectionScreenState();
}

class _OrganizationSelectionScreenState
    extends State<OrganizationSelectionScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.organizations.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectOrganization(widget.organizations.single);
        }
      });
    }
  }

  Future<void> _selectOrganization(OrganizationDto organization) async {
    final rally = await Navigator.of(context).push<RallyDto>(
      MaterialPageRoute<RallyDto>(
        builder: (_) => RallySelectionScreen(
          session: AppSession(user: widget.user, organization: organization),
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (rally != null && mounted) {
      Navigator.of(context)
          .pop(RallySetupSelection(organization: organization, rally: rally));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select organization')),
    body: SafeArea(
      child: widget.organizations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No organizations are available for ${widget.user.displayName.isEmpty ? widget.user.emailAddress ?? 'this account' : widget.user.displayName}.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.organizations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final organization = widget.organizations[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(organization.name ?? 'Unnamed organization'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectOrganization(organization),
                  ),
                );
              },
            ),
    ),
  );
}
