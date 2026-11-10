import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_session.dart';
import '../models/route_item_display.dart';
import 'settings_screen.dart';
import '../widgets/direction_alert_scope.dart';
import '../widgets/plan_component.dart';
import '../widgets/precision_drive_calibration_gate.dart';
import '../widgets/rally_map.dart';
import '../widgets/rallymaster_about_dialog.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({
    super.key,
    required this.session,
    required this.accessToken,
  });

  final AppSession session;
  final Future<String> Function() accessToken;

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  static const _dividerExtent = 16.0;
  final _planComponentKey = GlobalKey<PlanComponentState>();
  final _mapKey = GlobalKey<RallyMapState>();
  double _splitRatio = 0.5;
  PlanSaveState _planSaveState = const PlanSaveState(
    isDirty: false,
    isSaving: false,
  );
  List<RouteItemDisplay> _mapRouteItems = const [];
  var _allowPop = false;

  @override
  void initState() {
    super.initState();
    // Route planning is an active in-vehicle workflow. Keep the display awake
    // for its duration, while allowing normal timeout behavior elsewhere.
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePrecisionDrive();
    });
  }

  Future<void> _preparePrecisionDrive() async {
    if (!mounted) return;
    final sensorFusion = ref.read(sensorFusionServiceProvider)
      ..start()
      ..setEnabled(true)
      ..setLowSpeedAssistEnabled(true);
    final restored = await restorePrecisionDriveCalibration(ref);
    if (!restored && mounted) sensorFusion.requestCalibration();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _resize(double delta, double availableExtent) {
    if (availableExtent <= 0) return;
    setState(
      () => _splitRatio = (_splitRatio + delta / availableExtent)
          .clamp(0.15, 0.85)
          .toDouble(),
    );
  }

  Future<bool> _canLeavePlanning() async {
    if (_planSaveState.isSaving) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait for the route to finish saving.')),
        );
      }
      return false;
    }

    if (!_planSaveState.isDirty) return true;

    final discardChanges = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Your unsaved route instructions and checkpoints will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep planning'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discardChanges == true;
  }

  Future<void> _leavePlanning() async {
    if (await _canLeavePlanning() && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (!didPop) _leavePlanning();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowPop,
    onPopInvokedWithResult: _onPopInvoked,
    child: DirectionAlertScope(
      child: PrecisionDriveCalibrationGate(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back to route actions',
              onPressed: _leavePlanning,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(_title),
            actions: [
              TextButton.icon(
                onPressed: !_planSaveState.isDirty || _planSaveState.isSaving
                    ? null
                    : () => _planComponentKey.currentState?.save(),
                icon: _planSaveState.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
              PopupMenuButton<_PlanMenuAction>(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onSelected: (action) {
                  switch (action) {
                    case _PlanMenuAction.settings:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RallyMasterSettingsScreen(),
                        ),
                      );
                    case _PlanMenuAction.about:
                      showDialog<void>(
                        context: context,
                        builder: (_) => const RallyMasterAboutDialog(),
                      );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _PlanMenuAction.settings,
                    child: Text('Settings'),
                  ),
                  PopupMenuItem(
                    value: _PlanMenuAction.about,
                    child: Text('About'),
                  ),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final portrait =
                  MediaQuery.orientationOf(context) == Orientation.portrait;
              final availableExtent =
                  (portrait ? constraints.maxHeight : constraints.maxWidth) -
                  _dividerExtent;
              final firstExtent = availableExtent * _splitRatio;
              final secondExtent = availableExtent - firstExtent;
              final divider = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => _resize(
                  portrait ? details.delta.dy : details.delta.dx,
                  availableExtent,
                ),
                child: MouseRegion(
                  cursor: portrait
                      ? SystemMouseCursors.resizeUpDown
                      : SystemMouseCursors.resizeLeftRight,
                  child: SizedBox(
                    height: portrait ? _dividerExtent : null,
                    width: portrait ? null : _dividerExtent,
                    child: Center(
                      child: Container(
                        height: portrait ? 4 : 48,
                        width: portrait ? 48 : 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              return portrait
                  ? Column(
                      children: [
                        SizedBox(
                          height: firstExtent,
                          child: RallyMap(
                            key: _mapKey,
                            routeItems: _mapRouteItems,
                            onRouteItemTap: _onMapRouteItemTap,
                          ),
                        ),
                        divider,
                        SizedBox(
                          height: secondExtent,
                          child: PlanComponent(
                            key: _planComponentKey,
                            session: widget.session,
                            accessToken: widget.accessToken,
                            onSaveStateChanged: _onPlanSaveStateChanged,
                            onRouteItemsChanged: _onRouteItemsChanged,
                            onRouteItemSelected: _onTableRouteItemTap,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: firstExtent,
                          child: RallyMap(
                            key: _mapKey,
                            routeItems: _mapRouteItems,
                            onRouteItemTap: _onMapRouteItemTap,
                          ),
                        ),
                        divider,
                        SizedBox(
                          width: secondExtent,
                          child: PlanComponent(
                            key: _planComponentKey,
                            session: widget.session,
                            accessToken: widget.accessToken,
                            onSaveStateChanged: _onPlanSaveStateChanged,
                            onRouteItemsChanged: _onRouteItemsChanged,
                            onRouteItemSelected: _onTableRouteItemTap,
                          ),
                        ),
                      ],
                    );
            },
          ),
        ),
      ),
    ),
  );

  String get _title {
    final rallyName = widget.session.rally?.name ?? 'Rally';
    final routeName = widget.session.route?.name ?? 'Route';
    return '$rallyName — $routeName';
  }

  void _onPlanSaveStateChanged(PlanSaveState state) {
    if (!mounted) return;
    setState(() => _planSaveState = state);
  }

  void _onRouteItemsChanged(List<RouteItemDisplay> routeItems) {
    if (!mounted) return;
    setState(() => _mapRouteItems = routeItems);
  }

  void _onTableRouteItemTap(RouteItemDisplay routeItem) {
    _mapKey.currentState?.centerOnRouteItem(routeItem);
  }

  void _onMapRouteItemTap(RouteItemDisplay routeItem) {
    _planComponentKey.currentState?.selectRouteItem(routeItem);
  }
}

enum _PlanMenuAction { settings, about }
