import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/route_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/rally_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import 'create_route_screen.dart';

class SelectRouteScreen extends StatefulWidget {
  const SelectRouteScreen({
    super.key,
    required this.session,
    required this.rally,
    required this.accessToken,
  });

  final AppSession session;
  final RallyDto rally;
  final Future<String> Function() accessToken;

  @override
  State<SelectRouteScreen> createState() => _SelectRouteScreenState();
}

class _SelectRouteScreenState extends State<SelectRouteScreen> {
  List<RouteDto> _routes = const [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final rallyId = widget.rally.serverId;
    if (rallyId == null) {
      setState(() {
        _loading = false;
        _error = 'The selected rally has no server id.';
      });
      return;
    }
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
      final routes = await provider.listRallyRoutes(rallyId);
      if (mounted) setState(() => _routes = routes);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load routes: $error');
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createRoute() async {
    final route = await Navigator.of(context).push<RouteDto>(
      MaterialPageRoute<RouteDto>(
        builder: (_) => CreateRouteScreen(
          session: widget.session,
          rally: widget.rally,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (route != null && mounted) Navigator.of(context).pop(route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Select route'),
          actions: [
            IconButton(
              tooltip: 'Add route',
              onPressed: _loading ? null : _createRoute,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      );

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadRoutes, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_routes.isEmpty) {
      return const Center(
        child: Text('No routes for this rally. Use + to create one.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _routes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final route = _routes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text(route.name ?? 'Unnamed route'),
            subtitle: route.description == null || route.description!.isEmpty
                ? null
                : Text(route.description!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pop(route),
          ),
        );
      },
    );
  }
}
