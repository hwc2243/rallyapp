import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/organization_dto.dart';
import '../models/organization_membership_dto.dart';
import '../models/rally_dto.dart';
import '../models/rally_setup_selection.dart';
import '../models/user_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/organization_membership_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
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
  int? _selectingOrganizationId;
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
    final organizationId = organization.serverId;
    if (organizationId == null) {
      _showError('The selected organization has no server id.');
      return;
    }
    if (_selectingOrganizationId != null) return;

    setState(() => _selectingOrganizationId = organizationId);
    try {
      final membership = await _loadMembership(organizationId);
      if (membership == null) {
        _showError('You are not a member of this organization.');
        return;
      }
      if (!mounted) return;

      final session = AppSession(
        user: widget.user,
        organization: organization,
        organizationMembership: membership,
      );
      final rally = await Navigator.of(context).push<RallyDto>(
        MaterialPageRoute<RallyDto>(
          builder: (_) => RallySelectionScreen(
            session: session,
            accessToken: widget.accessToken,
          ),
        ),
      );
      if (rally != null && mounted) {
        Navigator.of(context).pop(
          RallySetupSelection(
            organization: organization,
            organizationMembership: membership,
            rally: rally,
          ),
        );
      }
    } catch (error) {
      _showError('Unable to load your organization membership: $error');
    } finally {
      if (mounted) {
        setState(() => _selectingOrganizationId = null);
      }
    }
  }

  Future<OrganizationMembershipDto?> _loadMembership(int organizationId) async {
    final tenantProvider = TenantDiscriminatorProvider()
      ..setOrganizationId(organizationId);
    final httpClient = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final provider = OrganizationMembershipProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    try {
      return await provider.me();
    } finally {
      provider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                    onTap: _selectingOrganizationId == null
                        ? () => _selectOrganization(organization)
                        : null,
                  ),
                );
              },
            ),
    ),
  );
}
