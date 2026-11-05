import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_session.dart';
import 'settings_screen.dart';
import '../widgets/direction_alert_scope.dart';
import '../widgets/plan_component.dart';
import '../widgets/rally_map.dart';
import '../widgets/rallymaster_about_dialog.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.session,
    required this.accessToken,
  });

  final AppSession session;
  final Future<String> Function() accessToken;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const _dividerExtent = 16.0;
  final _planComponentKey = GlobalKey<PlanComponentState>();
  double _splitRatio = 0.5;
  PlanSaveState _planSaveState = const PlanSaveState(
    isDirty: false,
    isSaving: false,
  );

  @override
  void initState() {
    super.initState();
    // Route planning is an active in-vehicle workflow. Keep the display awake
    // for its duration, while allowing normal timeout behavior elsewhere.
    WakelockPlus.enable();
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

  @override
  Widget build(BuildContext context) => DirectionAlertScope(
    child: Scaffold(
      appBar: AppBar(
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
              PopupMenuItem(value: _PlanMenuAction.about, child: Text('About')),
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
                    SizedBox(height: firstExtent, child: const RallyMap()),
                    divider,
                    SizedBox(
                      height: secondExtent,
                      child: PlanComponent(
                        key: _planComponentKey,
                        session: widget.session,
                        accessToken: widget.accessToken,
                        onSaveStateChanged: _onPlanSaveStateChanged,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: firstExtent, child: const RallyMap()),
                    divider,
                    SizedBox(
                      width: secondExtent,
                      child: PlanComponent(
                        key: _planComponentKey,
                        session: widget.session,
                        accessToken: widget.accessToken,
                        onSaveStateChanged: _onPlanSaveStateChanged,
                      ),
                    ),
                  ],
                );
        },
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
}

enum _PlanMenuAction { settings, about }
