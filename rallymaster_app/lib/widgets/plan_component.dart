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
    this.onRouteItemsChanged,
    this.onRouteItemSelected,
  });

  final AppSession session;
  final Future<String> Function() accessToken;
  final ValueChanged<PlanSaveState>? onSaveStateChanged;
  final ValueChanged<List<RouteItemDisplay>>? onRouteItemsChanged;
  final ValueChanged<RouteItemDisplay>? onRouteItemSelected;

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
  RouteItemDisplay? _selectedRouteItem;
  _RouteItemFilter _itemFilter = _RouteItemFilter.all;

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

  void _notifyRouteItemsChanged() =>
      widget.onRouteItemsChanged?.call(List.unmodifiable(_filteredRouteItems));

  List<RouteItemDisplay> get _filteredRouteItems => _routeItems.where((item) {
    return switch (_itemFilter) {
      _RouteItemFilter.all => true,
      _RouteItemFilter.nris => item.item.itemType == 'NRI',
      _RouteItemFilter.checkpoints => item.item.itemType == 'CHECKPOINT',
    };
  }).toList();

  int get _nriCount =>
      _routeItems.where((item) => item.item.itemType == 'NRI').length;
  int get _checkpointCount =>
      _routeItems.where((item) => item.item.itemType == 'CHECKPOINT').length;

  void _setItemFilter(_RouteItemFilter filter) {
    setState(() {
      _itemFilter = filter;
      if (_selectedRouteItem != null &&
          !_filteredRouteItems.contains(_selectedRouteItem)) {
        _selectedRouteItem = null;
      }
    });
    _notifyRouteItemsChanged();
  }

  /// Scrolls the route-item table to a marker selected on the map.
  void scrollToRouteItem(RouteItemDisplay item) {
    final ordered = [..._filteredRouteItems]
      ..sort(
        (left, right) =>
            (left.item.position ?? 0).compareTo(right.item.position ?? 0),
      );
    final index = ordered.indexWhere((current) => identical(current, item));
    if (index < 0 || !_tableScrollController.hasClients) return;
    final offset = (index * 56.0).clamp(
      0.0,
      _tableScrollController.position.maxScrollExtent,
    );
    _tableScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Selects a route item from the map and brings its row into view.
  void selectRouteItem(RouteItemDisplay item) {
    if (!mounted) return;
    setState(() => _selectedRouteItem = item);
    scrollToRouteItem(item);
  }

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
          ..addAll(_routeItems);
        widget.session.checkpointDrafts
          ..clear()
          ..addAll(saved.checkpoints);
        _isDirty = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Route saved')));
      _notifyRouteItemsChanged();
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
            child: Column(
              children: [
                SegmentedButton<_RouteItemFilter>(
                  segments: [
                    ButtonSegment(
                      value: _RouteItemFilter.all,
                      label: _filterLabel('All', _routeItems.length),
                    ),
                    ButtonSegment(
                      value: _RouteItemFilter.nris,
                      label: _filterLabel('NRIs', _nriCount),
                    ),
                    ButtonSegment(
                      value: _RouteItemFilter.checkpoints,
                      label: _filterLabel('CHKPTs', _checkpointCount),
                    ),
                  ],
                  selected: {_itemFilter},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      _setItemFilter(selection.first),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RouteItemsTable(
                    items: _filteredRouteItems,
                    controller: _tableScrollController,
                    selectedItem: _selectedRouteItem,
                    onItemTap: _selectRouteItem,
                    onItemEdit: _editRouteItem,
                    onItemDelete: _confirmDeleteRouteItem,
                  ),
                ),
              ],
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

  Widget _filterLabel(String text, int count) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text),
      Text('$count', style: const TextStyle(fontSize: 11)),
    ],
  );

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
            onPressed: _checkpointAllowed()
                ? () => Navigator.of(context).pop(_RouteItemType.checkpoint)
                : null,
            child: const Text('Checkpoint'),
          ),
        ],
      ),
    );
    if (itemType == null || !mounted) return;

    if (itemType == _RouteItemType.checkpoint && !_checkpointAllowed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add the matching End Free Zone or End Transit NRI before adding a checkpoint.',
          ),
        ),
      );
      return;
    }

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
              ? List<RouteItemDisplay>.of(widget.session.routeItems)
              : _routeItems;
          final updatedItems = [...visibleItems, created];
          _routeItems = updatedItems;
          widget.session.routeItems
            ..clear()
            ..addAll(updatedItems);
          if (created.checkpoint != null) {
            widget.session.checkpointDrafts.add(created.checkpoint!);
          }
          _isDirty = true;
        });
        _notifySaveState();
        _notifyRouteItemsChanged();
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
        allowedInstructionTypes: _allowedInstructionTypes(),
        suggestedSpeed: _suggestedSpeed(),
        rallyDefaultSpeed: widget.session.route?.defaultSpeed,
        defaultPauseDurationMillis:
            widget.session.route?.defaultPauseDurationMillis,
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

  Future<void> _editRouteItem(RouteItemDisplay display) async {
    if (_creating || _isSaving) return;

    final item = display.item;
    RouteItemDisplay? updated;
    if (item.itemType == 'NRI') {
      final instruction = display.routeInstruction;
      if (instruction == null) {
        _showDetailsUnavailable('Route instruction');
        return;
      }
      final edited = await showDialog<RouteInstructionDto>(
        context: context,
        builder: (_) => RouteInstructionDetailsDialog(
          latitude: item.latitude ?? 0,
          longitude: item.longitude ?? 0,
          heading: item.heading ?? 0,
          distance: item.distance ?? 0,
          position: item.position ?? 0,
          instructionNumber: instruction.instructionNumber ?? 0,
          organizationId: item.organizationId ?? widget.session.organizationId,
          routeId: item.routeId ?? widget.session.route?.serverId,
          initialValue: instruction,
          allowedInstructionTypes: _allowedInstructionTypes(excluding: display),
          suggestedSpeed: _suggestedSpeed(excluding: display),
          rallyDefaultSpeed: widget.session.route?.defaultSpeed,
          defaultPauseDurationMillis:
              widget.session.route?.defaultPauseDurationMillis,
        ),
      );
      if (edited == null) return;
      updated = _displayForInstruction(edited);
    } else if (item.itemType == 'CHECKPOINT') {
      final checkpoint = display.checkpoint;
      if (checkpoint == null) {
        _showDetailsUnavailable('Checkpoint');
        return;
      }
      final edited = await showDialog<CheckpointDto>(
        context: context,
        builder: (_) => CheckpointDetailsDialog(
          latitude: item.latitude ?? 0,
          longitude: item.longitude ?? 0,
          heading: item.heading ?? 0,
          distance: item.distance ?? 0,
          position: item.position ?? 0,
          checkpointNumber: checkpoint.checkpointNumber ?? 0,
          organizationId: item.organizationId ?? widget.session.organizationId,
          routeId: item.routeId ?? widget.session.route?.serverId,
          initialValue: checkpoint,
        ),
      );
      if (edited == null) return;
      updated = _displayForCheckpoint(edited);
    }

    if (updated == null || !mounted) return;
    setState(() {
      _routeItems = _routeItems
          .map((current) => identical(current, display) ? updated! : current)
          .toList();
      if (identical(_selectedRouteItem, display)) {
        _selectedRouteItem = updated;
      }
      widget.session.routeItems
        ..clear()
        ..addAll(_routeItems);
      if (updated!.checkpoint != null) {
        final checkpoint = updated.checkpoint!;
        final index = widget.session.checkpointDrafts.indexWhere(
          (current) =>
              current.serverId == checkpoint.serverId ||
              (current.serverId == null &&
                  current.position == checkpoint.position),
        );
        if (index >= 0) {
          widget.session.checkpointDrafts[index] = checkpoint;
        } else {
          widget.session.checkpointDrafts.add(checkpoint);
        }
      }
      _isDirty = true;
    });
    _notifySaveState();
    _notifyRouteItemsChanged();
  }

  void _selectRouteItem(RouteItemDisplay display) {
    setState(() => _selectedRouteItem = display);
    widget.onRouteItemSelected?.call(display);
  }

  void _showDetailsUnavailable(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$itemName details are still loading.')),
    );
  }

  Future<void> _confirmDeleteRouteItem(RouteItemDisplay display) async {
    if (_creating || _isSaving) return;
    final isInstruction = display.item.itemType == 'NRI';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isInstruction ? 'Delete route instruction?' : 'Delete checkpoint?',
        ),
        content: Text(
          'This ${isInstruction ? 'route instruction' : 'checkpoint'} will be removed when you save the route.',
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
    if (confirmed == true && mounted) {
      _deleteRouteItem(display);
    }
  }

  void _deleteRouteItem(RouteItemDisplay display) {
    final remaining = _routeItems
        .where((current) => !identical(current, display))
        .toList();
    final renumbered = _renumberRouteItems(remaining);
    setState(() {
      _routeItems = renumbered;
      _selectedRouteItem = null;
      widget.session.routeItems
        ..clear()
        ..addAll(renumbered);
      widget.session.checkpointDrafts
        ..clear()
        ..addAll(
          renumbered
              .map((current) => current.checkpoint)
              .whereType<CheckpointDto>(),
        );
      _isDirty = true;
    });
    _notifySaveState();
    _notifyRouteItemsChanged();
  }

  List<RouteItemDisplay> _renumberRouteItems(List<RouteItemDisplay> items) {
    final ordered = [...items]
      ..sort(
        (left, right) =>
            (left.item.position ?? 0).compareTo(right.item.position ?? 0),
      );
    var instructionNumber = 0;
    var checkpointNumber = 0;
    return [
      for (var index = 0; index < ordered.length; index++)
        _renumberRouteItem(
          ordered[index],
          position: index + 1,
          instructionNumber: ordered[index].item.itemType == 'NRI'
              ? ++instructionNumber
              : null,
          checkpointNumber: ordered[index].item.itemType == 'CHECKPOINT'
              ? ++checkpointNumber
              : null,
        ),
    ];
  }

  RouteItemDisplay _renumberRouteItem(
    RouteItemDisplay display, {
    required int position,
    int? instructionNumber,
    int? checkpointNumber,
  }) {
    final instruction = display.routeInstruction;
    if (instruction != null) {
      return _displayForInstruction(
        RouteInstructionDto(
          id: instruction.id,
          serverId: instruction.serverId,
          itemType: instruction.itemType,
          position: position,
          latitude: instruction.latitude,
          longitude: instruction.longitude,
          heading: instruction.heading,
          distance: instruction.distance,
          notes: instruction.notes,
          deleted: instruction.deleted,
          organizationId: instruction.organizationId,
          routeId: instruction.routeId,
          instructionNumber: instructionNumber,
          instructionText: instruction.instructionText,
          instructionType: instruction.instructionType,
          speed: instruction.speed,
          pauseDurationMillis: instruction.pauseDurationMillis,
          transitDurationMillis: instruction.transitDurationMillis,
        ),
      );
    }

    final checkpoint = display.checkpoint;
    if (checkpoint != null) {
      return _displayForCheckpoint(
        CheckpointDto(
          id: checkpoint.id,
          serverId: checkpoint.serverId,
          itemType: checkpoint.itemType,
          position: position,
          latitude: checkpoint.latitude,
          longitude: checkpoint.longitude,
          heading: checkpoint.heading,
          distance: checkpoint.distance,
          notes: checkpoint.notes,
          deleted: checkpoint.deleted,
          organizationId: checkpoint.organizationId,
          routeId: checkpoint.routeId,
          checkpointNumber: checkpointNumber,
          checkpointType: checkpoint.checkpointType,
          name: checkpoint.name,
        ),
      );
    }
    return display;
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
      detail: checkpoint.name,
      checkpoint: checkpoint,
    );
  }

  int _nextPosition() {
    final existingItems = _routeItems.isEmpty
        ? widget.session.routeItems.map((display) => display.item)
        : _routeItems.map((planItem) => planItem.item);
    return existingItems
            .map((item) => item.position ?? 0)
            .fold(0, (highest, value) => value > highest ? value : highest) +
        1;
  }

  List<RouteItemDisplay> _planningItems({RouteItemDisplay? excluding}) {
    final items = _routeItems.isEmpty ? widget.session.routeItems : _routeItems;
    return items.where((item) => !identical(item, excluding)).toList()..sort(
      (left, right) =>
          (left.item.position ?? 0).compareTo(right.item.position ?? 0),
    );
  }

  List<String> _allowedInstructionTypes({RouteItemDisplay? excluding}) {
    String? open;
    for (final display in _planningItems(excluding: excluding)) {
      final type = display.routeInstruction?.instructionType;
      if (type == 'BEGIN_FREE_ZONE') open = 'FREE';
      if (type == 'BEGIN_TRANSIT') open = 'TRANSIT';
      if (type == 'END_FREE_ZONE' && open == 'FREE') open = null;
      if (type == 'END_TRANSIT' && open == 'TRANSIT') open = null;
    }
    if (open == 'FREE') return const ['STANDARD', 'END_FREE_ZONE'];
    if (open == 'TRANSIT') return const ['STANDARD', 'END_TRANSIT'];
    return const ['STANDARD', 'BEGIN_FREE_ZONE', 'BEGIN_TRANSIT'];
  }

  bool _checkpointAllowed() => _allowedInstructionTypes().length == 3;

  double? _suggestedSpeed({RouteItemDisplay? excluding}) {
    final instructions = _planningItems(excluding: excluding)
        .map((item) => item.routeInstruction)
        .whereType<RouteInstructionDto>();
    for (final instruction in instructions.toList().reversed) {
      if (instruction.speed != null) return instruction.speed;
    }
    return widget.session.route?.defaultSpeed;
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
        ? widget.session.routeItems.map((display) => display.item)
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
    if (!mounted) return;
    setState(() {
      _routeItems = List.of(widget.session.routeItems);
      _routeItemsLoaded = true;
    });
    _notifySaveState();
    _notifyRouteItemsChanged();
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

enum _RouteItemFilter { all, nris, checkpoints }
