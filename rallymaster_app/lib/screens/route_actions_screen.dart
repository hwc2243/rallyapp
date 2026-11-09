import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/route_dto.dart';
import '../models/route_item_display.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/rally_provider.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import 'plan_screen.dart';

enum RouteActionResult { plan, deleted }

/// The actions available after a route and its items have been selected.
class RouteActionsScreen extends StatefulWidget {
  const RouteActionsScreen({
    super.key,
    required this.session,
    required this.rally,
    required this.route,
    required this.routeItems,
    required this.accessToken,
  });

  final AppSession session;
  final RallyDto rally;
  final RouteDto route;
  final List<RouteItemDisplay> routeItems;
  final Future<String> Function() accessToken;

  @override
  State<RouteActionsScreen> createState() => _RouteActionsScreenState();
}

class _RouteActionsScreenState extends State<RouteActionsScreen> {
  bool _deleting = false;
  bool _publishing = false;
  late RouteDto _route;

  @override
  void initState() {
    super.initState();
    _route = widget.route;
  }

  Future<void> _showNotImplemented(String action) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(action),
      content: const Text('Not yet implemented.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> _openPlan() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PlanScreen(
        session: AppSession(
          user: widget.session.user,
          organization: widget.session.organization,
          organizationMembership: widget.session.organizationMembership,
          rally: widget.rally,
          route: _route,
          routeItems: widget.routeItems,
        ),
        accessToken: widget.accessToken,
      ),
    ),
  );

  Future<void> _deleteRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'Delete “${widget.route.name ?? 'this route'}” and its '
          '${widget.routeItems.length} route item${widget.routeItems.length == 1 ? '' : 's'}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final routeId = widget.route.serverId;
    if (routeId == null) {
      _showError('The selected route has no server id.');
      return;
    }
    setState(() => _deleting = true);
    final tenantProvider = TenantDiscriminatorProvider()
      ..setOrganizationId(widget.session.organizationId);
    final httpClient = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final provider = RouteProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    try {
      // Route.items has ALL/orphan-removal on the server, so this also deletes
      // every persisted route item in the same operation.
      await provider.delete(routeId);
      if (mounted) Navigator.of(context).pop(RouteActionResult.deleted);
    } catch (error) {
      _showError('Unable to delete route: $error');
    } finally {
      provider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _publishRoute() async {
    final routeId = _route.serverId;
    final rallyId = widget.rally.serverId;
    if (routeId == null || rallyId == null) {
      _showError('The selected rally or route has no server id.');
      return;
    }

    setState(() => _publishing = true);
    final tenantProvider = TenantDiscriminatorProvider()
      ..setOrganizationId(widget.session.organizationId);
    final httpClient = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final rallyProvider = RallyProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    final routeProvider = RouteProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    try {
      final hasEventPassword = await rallyProvider.hasEventPassword(rallyId);
      final password = hasEventPassword
          ? null
          : await _promptForEventPassword();
      if (!mounted || (!hasEventPassword && password == null)) return;

      final published = await routeProvider.publishRoute(routeId, password);
      if (!mounted) return;
      setState(() => _route = published);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route published and ready for competitors.'),
        ),
      );
    } catch (_) {
      _showError('Unable to publish the route. Please try again.');
    } finally {
      rallyProvider.dispose();
      routeProvider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<String?> _promptForEventPassword() async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the shared event password competitors will use when they register for any route in “${widget.rally.name ?? 'this rally'}”.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              autofocus: true,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) =>
                  Navigator.of(dialogContext).pop(value.trim()),
              decoration: const InputDecoration(
                labelText: 'Event password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(passwordController.text.trim()),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (!mounted || password == null) return null;
    if (password.isEmpty) {
      _showError('An event password is required to publish this route.');
      return null;
    }
    return password;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasRouteItems = widget.routeItems.isNotEmpty;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final valueStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w600);
    return Scaffold(
      appBar: AppBar(title: const Text('Route actions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ORGANIZATION', style: labelStyle),
              Text(
                widget.session.organization.name ?? 'Unnamed organization',
                style: valueStyle,
              ),
              const SizedBox(height: 8),
              Text('RALLY', style: labelStyle),
              Text(widget.rally.name ?? 'Unnamed rally', style: valueStyle),
              const SizedBox(height: 8),
              Text('ROUTE', style: labelStyle),
              Text(_route.name ?? 'Unnamed route', style: valueStyle),
              const SizedBox(height: 16),
              Text(
                hasRouteItems
                    ? '${widget.routeItems.length} route item${widget.routeItems.length == 1 ? '' : 's'} ready to use.'
                    : 'This route has no route items yet.',
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _deleting || _publishing ? null : _openPlan,
                icon: const Icon(Icons.edit_road),
                label: const Text('Plan'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _deleting || _publishing ? null : _deleteRoute,
                icon: _deleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(_deleting ? 'Deleting…' : 'Delete'),
              ),
              if (hasRouteItems) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleting || _publishing
                      ? null
                      : () => _showNotImplemented('Drive'),
                  icon: const Icon(Icons.drive_eta),
                  label: const Text('Drive'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _deleting || _publishing || _route.status == 'ACTIVE'
                      ? null
                      : _publishRoute,
                  icon: _publishing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _route.status == 'ACTIVE'
                              ? Icons.check_circle_outline
                              : Icons.publish,
                        ),
                  label: Text(
                    _publishing
                        ? 'Publishing…'
                        : _route.status == 'ACTIVE'
                        ? 'Published'
                        : 'Publish',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleting || _publishing
                      ? null
                      : () => _showNotImplemented('View'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
