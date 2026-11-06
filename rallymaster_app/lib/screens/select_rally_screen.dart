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
    } else if (action == RouteActionResult.deleted && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Route deleted.')));
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
          child: ListTile(
            leading: const Icon(Icons.route),
            title: Text(rally.name ?? 'Unnamed rally'),
            subtitle: rally.description == null || rally.description!.isEmpty
                ? null
                : Text(rally.description!),
            trailing: rally.date == null ? null : Text(rally.date!),
            onTap: () => _selectRally(rally),
          ),
        );
      },
    );
  }
}
