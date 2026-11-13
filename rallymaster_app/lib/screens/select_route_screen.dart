import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/route_dto.dart';
import '../models/route_selection.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/rally_provider.dart';
import '../providers/route_provider.dart';
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
    if (route != null && mounted) await _selectRoute(route);
  }

  Future<void> _editRoute(RouteDto route) async {
    if (route.status != null &&
        route.status != 'PLAN' &&
        route.status != 'PLANNING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only planning routes can be edited.')),
      );
      return;
    }
    final updated = await Navigator.of(context).push<RouteDto>(
      MaterialPageRoute<RouteDto>(
        builder: (_) => CreateRouteScreen(
          session: widget.session,
          rally: widget.rally,
          accessToken: widget.accessToken,
          initialRoute: route,
        ),
      ),
    );
    if (updated != null && mounted) await _loadRoutes();
  }

  Future<void> _deleteRoute(RouteDto route) async {
    final routeId = route.serverId;
    if (routeId == null) return;
    if (route.status != null &&
        route.status != 'PLAN' &&
        route.status != 'PLANNING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only planning routes can be deleted.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'Delete “${route.name ?? 'this route'}” and all of its instructions and checkpoints? This cannot be undone.',
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
    RouteProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RouteProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      await provider.delete(routeId);
      if (mounted) {
        await _loadRoutes();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Route deleted.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to delete route: $error');
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectRoute(RouteDto route) async {
    final routeId = route.serverId;
    if (routeId == null) {
      setState(() => _error = 'The selected route has no server id.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RouteProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RouteProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final routeItems = await provider.listRouteItems(routeId);
      if (mounted) {
        Navigator.of(context)
            .pop(RouteSelection(route: route, routeItems: routeItems));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to load route items: $error');
      }
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
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _loading ? null : () => _selectRoute(route),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name ?? 'Unnamed route',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (route.description != null &&
                            route.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            route.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit route',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _loading
                                  ? null
                                  : () => _editRoute(route),
                            ),
                            IconButton(
                              tooltip: 'Delete route',
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: _loading
                                  ? null
                                  : () => _deleteRoute(route),
                            ),
                            if (route.status != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                route.status!,
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
