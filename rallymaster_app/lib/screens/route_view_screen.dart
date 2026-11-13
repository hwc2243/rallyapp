import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/route_item_display.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import '../models/route_timing_plan_view.dart';

class RouteViewScreen extends StatefulWidget {
  const RouteViewScreen({
    super.key,
    required this.session,
    required this.items,
    required this.accessToken,
  });
  final AppSession session;
  final List<RouteItemDisplay> items;
  final Future<String> Function() accessToken;
  @override
  State<RouteViewScreen> createState() => _RouteViewScreenState();
}

class _RouteViewScreenState extends State<RouteViewScreen> {
  RouteTimingPlanView? _plan;
  String? _error;
  var _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routeId = widget.session.route?.serverId;
    if (routeId == null) {
      setState(() {
        _loading = false;
        _error = 'The selected route has no server id.';
      });
      return;
    }
    final tenant = TenantDiscriminatorProvider()
      ..setOrganizationId(widget.session.organizationId);
    final client = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final provider = RouteProvider(httpClient: client, tenantProvider: tenant);
    try {
      final plan = await provider.getTimingPlan(routeId);
      if (mounted) setState(() => _plan = plan);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      provider.dispose();
      tenant.dispose();
      client.client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  String _item(RouteItemDisplay item) => item.item.itemType == 'NRI'
      ? 'NRI ${item.instructionNumber ?? ''}'
      : 'CHKPT ${item.checkpoint?.checkpointNumber ?? ''}';
  String _description(RouteItemDisplay item) => item.item.itemType == 'NRI'
      ? (item.routeInstruction?.instructionText ?? '')
      : ([
          item.checkpoint?.checkpointType,
          item.checkpoint?.name,
        ].whereType<String>().where((v) => v.isNotEmpty).join(' - '));

  String _pause(RouteItemDisplay item) {
    final millis = item.routeInstruction?.pauseDurationMillis;
    if (millis == null || millis <= 0) return '';
    final seconds = millis ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Route timing plan')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text('Unable to load timing plan: $_error'))
        : _plan == null
        ? const Center(
            child: Text(
              'No timing plan is available. Calculate the timing plan first.',
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ITEM')),
                  DataColumn(label: Text('DISTANCE')),
                  DataColumn(label: Text('ARRIVAL')),
                  DataColumn(label: Text('PAUSE')),
                  DataColumn(label: Text('DESCRIPTION')),
                ],
                rows:
                    (List<RouteItemDisplay>.of(widget.items)..sort(
                          (a, b) => (a.item.position ?? 0).compareTo(
                            b.item.position ?? 0,
                          ),
                        ))
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(Text(_item(item))),
                              DataCell(
                                Text(
                                  (item.item.distance ?? 0).toStringAsFixed(3),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _plan!.arrivals[item.item.serverId] ?? '—',
                                ),
                              ),
                              DataCell(Text(_pause(item))),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    _description(item),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
  );
}
