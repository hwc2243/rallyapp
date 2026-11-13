import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/rally_setup_selection.dart';
import '../models/route_selection.dart';
import '../providers/external_api_client.dart';
import '../providers/rally_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import '../network/service_builder_http_client.dart';
import 'create_rally_screen.dart';
import 'route_actions_screen.dart';
import 'select_route_screen.dart';

class SelectRallyScreen extends StatefulWidget {
  const SelectRallyScreen({
    super.key,
    required this.session,
    required this.accessToken,
  });

  final AppSession session;
  final Future<String> Function() accessToken;

  @override
  State<SelectRallyScreen> createState() => _SelectRallyScreenState();
}

class _SelectRallyScreenState extends State<SelectRallyScreen> {
  List<RallyDto> _rallies = const [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRallies();
  }

  Future<void> _loadRallies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RallyProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RallyProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final rallies = await provider.list();
      if (mounted) {
        setState(() => _rallies = rallies);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to load rallies: $error');
      }
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectRally(RallyDto rally) async {
    final selection = await Navigator.of(context).push<RouteSelection>(
      MaterialPageRoute<RouteSelection>(
        builder: (_) => SelectRouteScreen(
          session: widget.session,
          rally: rally,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (selection == null || !mounted) return;

    final action = await Navigator.of(context).push<RouteActionResult>(
      MaterialPageRoute<RouteActionResult>(
        builder: (_) => RouteActionsScreen(
          session: widget.session,
          rally: rally,
          route: selection.route,
          routeItems: selection.routeItems,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (action == RouteActionResult.plan && mounted) {
      Navigator.of(context).pop(
        RallySetupSelection(
          organization: widget.session.organization,
          organizationMembership: widget.session.organizationMembership,
          rally: rally,
          route: selection.route,
          routeItems: selection.routeItems,
        ),
      );
    } else if (action == RouteActionResult.chooseRoute && mounted) {
      await _selectRally(rally);
    }
  }

  Future<void> _createRally() async {
    final rally = await Navigator.of(context).push<RallyDto>(
      MaterialPageRoute<RallyDto>(
        builder: (_) => CreateRallyScreen(
          session: widget.session,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (rally != null && mounted) {
      await _selectRally(rally);
    }
  }

  Future<void> _editRally(RallyDto rally) async {
    final updated = await Navigator.of(context).push<RallyDto>(
      MaterialPageRoute<RallyDto>(
        builder: (_) => CreateRallyScreen(
          session: widget.session,
          accessToken: widget.accessToken,
          rally: rally,
        ),
      ),
    );
    if (updated != null && mounted) await _loadRallies();
  }

  Future<void> _deleteRally(RallyDto rally) async {
    final rallyId = rally.serverId;
    if (rallyId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete rally?'),
        content: Text(
          'Delete “${rally.name ?? 'this rally'}” and every planning route, instruction, and checkpoint it contains? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RallyProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RallyProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      await provider.delete(rallyId);
      if (!mounted) return;
      await _loadRallies();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rally deleted.')));
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to delete rally: $error');
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Select rally'),
      actions: [
        IconButton(
          tooltip: 'Add rally',
          onPressed: _loading ? null : _createRally,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadRallies, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_rallies.isEmpty) {
      return const Center(child: Text('No rallies for this organization.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rallies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rally = _rallies[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectRally(rally),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rally.name ?? 'Unnamed rally',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (rally.description != null &&
                            rally.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            rally.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit rally',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _loading
                                  ? null
                                  : () => _editRally(rally),
                            ),
                            IconButton(
                              tooltip: 'Delete rally',
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: _loading
                                  ? null
                                  : () => _deleteRally(rally),
                            ),
                            if (rally.date != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                rally.date!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                    child: Center(child: Icon(Icons.chevron_right)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
