import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:rallymaster_ui/rallymaster_ui.dart';

import '../models/app_session.dart';
import '../models/checkpoint_dto.dart';
import '../models/route_item_display.dart';
import '../models/route_item_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/checkpoint_provider.dart';
import '../providers/route_instruction_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import '../services/precise_location_service.dart';
import 'checkpoint_details_dialog.dart';
import 'plan_odometer_dialog.dart';
import 'route_items_table.dart';

/// Reusable planning pane. Planning tools are displayed above its mileage bar.
class PlanComponent extends ConsumerStatefulWidget {
  const PlanComponent({
    super.key,
    required this.session,
    required this.accessToken,
  });

  final AppSession session;
  final Future<String> Function() accessToken;

  @override
  ConsumerState<PlanComponent> createState() => _PlanComponentState();
}

class _PlanComponentState extends ConsumerState<PlanComponent> {
  bool _creating = false;
  final _tableScrollController = ScrollController();
  List<RouteItemDisplay> _routeItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settingsProvider.notifier)
        ..setDebugEditionOverride(DebugEditionOverride.precisionDrive)
        ..setSensorFusionEnabled(true);
      ref.read(sensorFusionServiceProvider)
        ..start()
        ..setEnabled(true)
        ..setLowSpeedAssistEnabled(true);
      _loadInitialRouteItemDetails();
    });
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final odometer = ref.watch(odometerProvider);
    final miles = odometer.totalDistance / 1609.344;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RouteItemsTable(
              items: _routeItems,
              controller: _tableScrollController,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MILEAGE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (odometer.direction != OdometerDirection.forward) ...[
                        const SizedBox(width: 6),
                        OdometerDirectionIndicator(
                          direction: odometer.direction,
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => const PlanOdometerDialog(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        '${miles.toStringAsFixed(3)} mi',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FloatingActionButton.small(
                heroTag: 'add-route-item',
                tooltip: 'Add route item',
                onPressed: _creating ? null : () => _addRouteItem(odometer),
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addRouteItem(OdometerState odometer) async {
    final itemType = await showDialog<_RouteItemType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add route item'),
        content: const Text('What would you like to add?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(_RouteItemType.nri),
            child: const Text('NRI'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_RouteItemType.checkpoint),
            child: const Text('Checkpoint'),
          ),
        ],
      ),
    );
    if (itemType == null || !mounted) return;

    setState(() => _creating = true);
    try {
      final location = itemType == _RouteItemType.checkpoint
          ? await _obtainCheckpointLocation()
          : await _obtainCurrentLocation(odometer);
      if (location == null || !mounted) return;
      final created = itemType == _RouteItemType.checkpoint
          ? await _createCheckpoint(location, odometer.totalDistance)
          : _createLocalNri(location, odometer.totalDistance);
      if (created == null || !mounted) return;
      if (mounted) {
        setState(() {
          final visibleItems = _routeItems.isEmpty
              ? widget.session.routeItems
                    .map((item) => RouteItemDisplay(item: item))
                    .toList()
              : _routeItems;
          widget.session.routeItems.add(created.item);
          if (created.checkpoint != null) {
            widget.session.checkpointDrafts.add(created.checkpoint!);
          }
          _routeItems = [...visibleItems, created];
        });
        _scrollTableToBottom();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to add route item: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<Position?> _obtainCheckpointLocation() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            SizedBox(width: 20),
            Expanded(child: Text('Obtaining precise location')),
          ],
        ),
      ),
    );
    try {
      return await PreciseLocationService().obtain();
    } finally {
      if (mounted && navigator.canPop()) navigator.pop();
    }
  }

  Future<Position> _obtainCurrentLocation(OdometerState odometer) async {
    if (odometer.latitude != 0.0 || odometer.longitude != 0.0) {
      return Position(
        longitude: odometer.longitude,
        latitude: odometer.latitude,
        timestamp: DateTime.now(),
        accuracy: odometer.lastAccuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: odometer.lastValidBearing ?? 0,
        headingAccuracy: 0,
        speed: odometer.currentSpeed,
        speedAccuracy: 0,
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  RouteItemDisplay _createLocalNri(Position location, double distanceMeters) {
    final item = RouteItemDto(
      itemType: 'NRI',
      position: _nextPosition(),
      latitude: location.latitude,
      longitude: location.longitude,
      heading: _headingFrom(location),
      distance: distanceMeters / 1609.344,
      organizationId: widget.session.organizationId,
      routeId: widget.session.route?.serverId,
    );
    return RouteItemDisplay(item: item, detail: 'NRI');
  }

  Future<RouteItemDisplay?> _createCheckpoint(
    Position location,
    double distanceMeters,
  ) async {
    final checkpoint = await showDialog<CheckpointDto>(
      context: context,
      builder: (_) => CheckpointDetailsDialog(
        latitude: location.latitude,
        longitude: location.longitude,
        heading: _headingFrom(location),
        distance: distanceMeters / 1609.344,
        position: _nextPosition(),
        checkpointNumber: _nextCheckpointNumber(),
        organizationId: widget.session.organizationId,
        routeId: widget.session.route?.serverId,
      ),
    );
    if (checkpoint == null) return null;
    return RouteItemDisplay(
      item: RouteItemDto(
        itemType: checkpoint.itemType,
        position: checkpoint.position,
        latitude: checkpoint.latitude,
        longitude: checkpoint.longitude,
        heading: checkpoint.heading,
        distance: checkpoint.distance,
        notes: checkpoint.notes,
        organizationId: checkpoint.organizationId,
        routeId: checkpoint.routeId,
      ),
      detail: checkpoint.name ?? 'Checkpoint ${checkpoint.checkpointNumber}',
      checkpoint: checkpoint,
    );
  }

  int _nextPosition() {
    final existingItems = _routeItems.isEmpty
        ? widget.session.routeItems
        : _routeItems.map((planItem) => planItem.item);
    return existingItems
            .map((item) => item.position ?? 0)
            .fold(0, (highest, value) => value > highest ? value : highest) +
        1;
  }

  int _nextCheckpointNumber() {
    var highest = 0;
    for (final item in _routeItems) {
      final checkpointNumber = item.checkpoint?.checkpointNumber;
      if (checkpointNumber != null && checkpointNumber > highest) {
        highest = checkpointNumber;
      }
    }
    if (highest > 0) return highest + 1;
    final existingItems = _routeItems.isEmpty
        ? widget.session.routeItems
        : _routeItems.map((item) => item.item);
    return existingItems.where((item) => item.itemType == 'CHECKPOINT').length +
        1;
  }

  int _headingFrom(Position location) {
    if (!location.heading.isFinite || location.heading < 0) return 0;
    return location.heading.round() % 360;
  }

  Future<void> _loadInitialRouteItemDetails() async {
    final items = await _loadRouteItemDetails(widget.session.routeItems);
    if (mounted) {
      setState(() {
        final currentUnsaved = _routeItems
            .where((item) => item.item.serverId == null)
            .toList();
        final loadedPositions = items
            .map((item) => item.item.position)
            .whereType<int>()
            .toSet();
        _routeItems = [
          ...items,
          ...currentUnsaved.where(
            (item) => !loadedPositions.contains(item.item.position),
          ),
        ];
      });
    }
  }

  Future<List<RouteItemDisplay>> _loadRouteItemDetails(
    List<RouteItemDto> items,
  ) async {
    if (items.isEmpty) return const [];
    final tenantProvider = TenantDiscriminatorProvider()
      ..setOrganizationId(widget.session.organizationId);
    final httpClient = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final routeInstructionProvider = RouteInstructionProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    final checkpointProvider = CheckpointProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    try {
      return await Future.wait(
        items.map((item) async {
          final itemId = item.serverId;
          if (itemId == null) {
            final checkpoint = _checkpointDraftFor(item);
            return RouteItemDisplay(
              item: item,
              detail: checkpoint?.name,
              checkpoint: checkpoint,
            );
          }
          try {
            if (item.itemType == 'NRI') {
              final instruction = await routeInstructionProvider.get(itemId);
              return RouteItemDisplay(
                item: item,
                detail: instruction?.instructionText,
              );
            }
            if (item.itemType == 'CHECKPOINT') {
              final checkpoint = await checkpointProvider.get(itemId);
              return RouteItemDisplay(
                item: item,
                detail: checkpoint?.name,
                checkpoint: checkpoint,
              );
            }
          } catch (_) {
            // Keep the shared route-item data visible if a detail fetch fails.
          }
          return RouteItemDisplay(item: item);
        }),
      );
    } finally {
      routeInstructionProvider.dispose();
      checkpointProvider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
    }
  }

  CheckpointDto? _checkpointDraftFor(RouteItemDto item) {
    if (item.itemType != 'CHECKPOINT') return null;
    for (final checkpoint in widget.session.checkpointDrafts) {
      if (checkpoint.position == item.position) return checkpoint;
    }
    return null;
  }

  void _scrollTableToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tableScrollController.hasClients) return;
      _tableScrollController.animateTo(
        _tableScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

enum _RouteItemType { nri, checkpoint }

