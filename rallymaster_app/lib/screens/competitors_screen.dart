import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/competitor_entry.dart';
import '../models/route_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';

/// Lists and manages the competitor teams registered for the selected route.
class CompetitorsScreen extends StatefulWidget {
  const CompetitorsScreen({
    super.key,
    required this.session,
    required this.route,
    required this.accessToken,
  });

  final AppSession session;
  final RouteDto route;
  final Future<String> Function() accessToken;

  @override
  State<CompetitorsScreen> createState() => _CompetitorsScreenState();
}

class _CompetitorsScreenState extends State<CompetitorsScreen> {
  List<CompetitorEntry> _competitors = const [];
  String? _error;
  int? _deletingEntryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompetitors();
  }

  Future<T> _withProvider<T>(
    Future<T> Function(RouteProvider provider) action,
  ) async {
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
      return await action(provider);
    } finally {
      provider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
    }
  }

  Future<void> _loadCompetitors() async {
    final routeId = widget.route.serverId;
    if (routeId == null) {
      setState(() {
        _loading = false;
        _error = 'The selected route has no server id.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final competitors = await _withProvider(
        (provider) => provider.listCompetitors(routeId),
      );
      if (mounted) setState(() => _competitors = competitors);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to load competitors: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteCompetitor(CompetitorEntry competitor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete competitor?'),
        content: Text(
          'Delete car ${competitor.carNumber ?? '—'} '
          '(${competitor.driverName} / ${competitor.navigatorName})? '
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
    if (routeId == null) return;
    setState(() => _deletingEntryId = competitor.entryId);
    try {
      await _withProvider(
        (provider) => provider.deleteCompetitor(routeId, competitor.entryId),
      );
      if (!mounted) return;
      setState(() {
        _competitors = _competitors
            .where((entry) => entry.entryId != competitor.entryId)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car ${competitor.carNumber ?? '—'} deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete competitor: $error')),
      );
    } finally {
      if (mounted) setState(() => _deletingEntryId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Competitors')),
    body: SafeArea(child: _buildBody(context)),
  );

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadCompetitors,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_competitors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No competitors have registered for this route.'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCompetitors,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('CAR')),
              DataColumn(label: Text('DRIVER')),
              DataColumn(label: Text('NAVIGATOR')),
              DataColumn(label: SizedBox.shrink()),
            ],
            rows: _competitors.map(_competitorRow).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _competitorRow(CompetitorEntry competitor) {
    final deleting = _deletingEntryId == competitor.entryId;
    return DataRow(
      cells: [
        DataCell(Text(competitor.carNumber?.toString() ?? '—')),
        DataCell(Text(competitor.driverName)),
        DataCell(Text(competitor.navigatorName)),
        DataCell(
          IconButton(
            tooltip: 'Delete car ${competitor.carNumber ?? ''}',
            onPressed: _deletingEntryId == null
                ? () => _deleteCompetitor(competitor)
                : null,
            icon: deleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );
  }
}
