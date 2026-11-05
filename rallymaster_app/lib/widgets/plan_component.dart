import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:rallymaster_ui/rallymaster_ui.dart';

import '../models/app_session.dart';
import '../models/checkpoint_dto.dart';
import '../models/route_item_display.dart';
import '../models/route_item_dto.dart';
import '../models/route_instruction_dto.dart';
import '../models/route_plan_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/checkpoint_provider.dart';
import '../providers/route_instruction_provider.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';
import '../services/precise_location_service.dart';
import 'checkpoint_details_dialog.dart';
import 'plan_odometer_dialog.dart';
import 'route_instruction_details_dialog.dart';
import 'route_items_table.dart';

/// Reusable planning pane. Planning tools are displayed above its mileage bar.
class PlanComponent extends ConsumerStatefulWidget {
  const PlanComponent({
    super.key,
    required this.session,
    required this.accessToken,
    this.onSaveStateChanged,
  });

  final AppSession session;
  final Future<String> Function() accessToken;
  final ValueChanged<PlanSaveState>? onSaveStateChanged;

  @override
  ConsumerState<PlanComponent> createState() => PlanComponentState();
}

class PlanSaveState {
  const PlanSaveState({required this.isDirty, required this.isSaving});

  final bool isDirty;
  final bool isSaving;
}

class PlanComponentState extends ConsumerState<PlanComponent> {
  bool _creating = false;
  bool _routeItemsLoaded = false;
  bool _isDirty = false;
  bool _isSaving = false;
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

  void _notifySaveState() => widget.onSaveStateChanged?.call(
    PlanSaveState(isDirty: _isDirty, isSaving: _isSaving),
  );

  /// Saves the complete local plan. Returns without mutation on failure so a
  /// user can retry after a connectivity problem.
  Future<void> save() async {
    if (_isSaving || !_isDirty) return;
    final routeId = widget.session.route?.serverId;
    if (routeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A saved route is required before saving its plan.'),
        ),
      );
      return;
    }

    final instructions = <RouteInstructionDto>[];
    final checkpoints = <CheckpointDto>[];
    for (final display in _routeItems) {
      if (display.item.itemType == 'NRI') {
        final instruction = display.routeInstruction;
        if (instruction == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Route instruction details have not finished loading.',
              ),
            ),
          );
          return;
        }
        instructions.add(instruction);
      } else if (display.item.itemType == 'CHECKPOINT') {
        final checkpoint = display.checkpoint;
        if (checkpoint == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkpoint details have not finished loading.'),
            ),
          );
          return;
        }
        checkpoints.add(checkpoint);
      }
    }

    setState(() => _isSaving = true);
    _notifySaveState();
    final tenantProvider = TenantDiscriminatorProvider()
      ..setOrganizationId(widget.session.organizationId);
    final httpClient = ServiceBuilderHttpClient(
      baseUrl: ExternalApiClient.defaultApiBaseUrl,
      headersProvider: () async => {
        'Authorization': 'Bearer ${await widget.accessToken()}',
      },
    );
    final routeProvider = RouteProvider(
      httpClient: httpClient,
      tenantProvider: tenantProvider,
    );
    try {
      final saved = await routeProvider.saveRoutePlan(
        routeId,
        RoutePlanDto(routeInstructions: instructions, checkpoints: checkpoints),
      );
      if (!mounted) return;
      setState(() {
        _routeItems =
            [
              ...saved.routeInstructions.map(_displayForInstruction),
              ...saved.checkpoints.map(_displayForCheckpoint),
            ]..sort(
              (left, right) =>
                  (left.item.position ?? 0).compareTo(right.item.position ?? 0),
            );
        widget.session.routeItems
          ..clear()
          ..addAll(_routeItems.map((display) => display.item));
        widget.session.checkpointDrafts
          ..clear()
          ..addAll(saved.checkpoints);
        _isDirty = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Route saved')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save route: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _notifySaveState();
      }
      routeProvider.dispose();
      tenantProvider.dispose();
      httpClient.client.close();
    }
  }

  RouteItemDisplay _displayForInstruction(RouteInstructionDto instruction) =>
      RouteItemDisplay(
        item: RouteItemDto(
          serverId: instruction.serverId,
          itemType: instruction.itemType,
          position: instruction.position,
          latitude: instruction.latitude,
          longitude: instruction.longitude,
          heading: instruction.heading,
          distance: instruction.distance,
          notes: instruction.notes,
          organizationId: instruction.organizationId,
          routeId: instruction.routeId,
        ),
        detail: instruction.instructionText,
        routeInstruction: instruction,
      );

  RouteItemDisplay _displayForCheckpoint(CheckpointDto checkpoint) =>
      RouteItemDisplay(
        item: RouteItemDto(
          serverId: checkpoint.serverId,
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
        detail: checkpoint.name,
        checkpoint: checkpoint,
      );

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
                onPressed: _creating || !_routeItemsLoaded
                    ? null
                    : () => _addRouteItem(odometer),
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
          : await _createLocalNri(location, odometer.totalDistance);
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
          _isDirty = true;
        });
        _notifySaveState();
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

  Future<RouteItemDisplay?> _createLocalNri(
    Position location,
    double distanceMeters,
  ) async {
    final position = _nextPosition();
    final instructionNumber = _nextInstructionNumber();
    final instruction = await showDialog<RouteInstructionDto>(
      context: context,
      builder: (_) => RouteInstructionDetailsDialog(
        latitude: location.latitude,
        longitude: location.longitude,
        heading: _headingFrom(location),
        distance: distanceMeters / 1609.344,
        position: position,
        instructionNumber: instructionNumber,
        organizationId: widget.session.organizationId,
        routeId: widget.session.route?.serverId,
      ),
    );
    if (instruction == null) return null;

    final item = RouteItemDto(
      itemType: 'NRI',
      position: instruction.position,
      latitude: instruction.latitude,
      longitude: instruction.longitude,
      heading: instruction.heading,
      distance: instruction.distance,
      notes: instruction.notes,
      organizationId: instruction.organizationId,
      routeId: instruction.routeId,
    );
    return RouteItemDisplay(
      item: item,
      detail: instruction.instructionText,
      routeInstruction: instruction,
    );
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

  int _nextInstructionNumber() {
    var highest = 0;
    for (final item in _routeItems) {
      final instructionNumber = item.instructionNumber;
      if (instructionNumber != null && instructionNumber > highest) {
        highest = instructionNumber;
      }
    }
    return highest + 1;
  }

  int _headingFrom(Position location) {
    if (!location.heading.isFinite || location.heading < 0) return 0;
    return location.heading.round() % 360;
  }

  Future<void> _loadInitialRouteItemDetails() async {
    try {
      final items = await _loadRouteItemDetails(widget.session.routeItems);
      if (!mounted) return;
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
    } finally {
      if (mounted) {
        setState(() => _routeItemsLoaded = true);
        _notifySaveState();
      }
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
                routeInstruction: instruction,
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
