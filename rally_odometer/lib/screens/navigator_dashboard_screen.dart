import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../providers/rally_time_offset_provider.dart';
import '../widgets/ble_connection_diagnostics.dart';
import '../widgets/connection_error_modal.dart';
import '../widgets/mileage_entry_dialog.dart';
import '../widgets/shared_overflow_popup_menu_button.dart';
import 'driver_dashboard_screen.dart';

/// Full-control Navigator layout. Remote Navigators send BLE commands, while
/// Controller Navigator View applies the same commands directly to its engine.
class NavigatorDashboardScreen extends ConsumerStatefulWidget {
  const NavigatorDashboardScreen({
    super.key,
    required this.isControllerEngine,
  });

  final bool isControllerEngine;

  @override
  ConsumerState<NavigatorDashboardScreen> createState() =>
      _NavigatorDashboardScreenState();
}

class _NavigatorDashboardScreenState
    extends ConsumerState<NavigatorDashboardScreen> {
  bool _hasConnected = false;

  void _send(
    ControllerCommandOpcode opcode, {
    double? numericValue,
    String? stringValue,
  }) {
    if (widget.isControllerEngine) {
      final odometer = ref.read(odometerProvider.notifier);
      switch (opcode) {
        case ControllerCommandOpcode.resetTotal:
          odometer.resetTotal();
        case ControllerCommandOpcode.resetInterval:
          odometer.resetInterval();
        case ControllerCommandOpcode.toggleHold:
          break;
        case ControllerCommandOpcode.bumpPlus:
          odometer.applyBump(true);
        case ControllerCommandOpcode.bumpMinus:
          odometer.applyBump(false);
        case ControllerCommandOpcode.setFprState:
          if (stringValue != null) {
            odometer.setDirection(OdometerDirection.values.firstWhere(
              (direction) => direction.name == stringValue,
            ));
          }
        case ControllerCommandOpcode.overrideMileage:
          if (numericValue != null) {
            odometer.setTotalDistance(numericValue);
          }
        case ControllerCommandOpcode.overrideIntervalMileage:
          if (numericValue != null) {
            odometer.setIntervalDistance(numericValue);
          }
        case ControllerCommandOpcode.setCalibrationFactor:
        case ControllerCommandOpcode.setMetric:
        case ControllerCommandOpcode.setDecimalMinutes:
        case ControllerCommandOpcode.setBumpAmount:
        case ControllerCommandOpcode.setBumpRequireDoubleTap:
        case ControllerCommandOpcode.setRallyTimeOffset:
          break;
      }
      return;
    }
    ref.read(bleTelemetryServiceProvider).sendCommand(
          ControllerCommand(
            opcode: opcode,
            numericValue: numericValue,
            stringValue: stringValue,
            timestamp: DateTime.now(),
          ),
        );
  }

  Future<void> _editMileage({
    required bool isTotal,
    required double meters,
    required bool isMetric,
  }) async {
    final unit = isMetric ? 'KM' : 'MI';
    final scale = isMetric ? 1000.0 : 1609.344;
    final entered = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MileageEntryDialog(
        initialValue: (meters / scale).toStringAsFixed(3),
        title: 'SET ${isTotal ? 'TOTAL' : 'INTERVAL'} MILEAGE ($unit)',
        decimalPlaces: 3,
        maxDigitsBeforeDecimal: 8,
      ),
    );
    if (entered == null) return;
    _send(
      isTotal
          ? ControllerCommandOpcode.overrideMileage
          : ControllerCommandOpcode.overrideIntervalMileage,
      numericValue: entered * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isControllerEngine) {
      ref.listen<AsyncValue<bool>>(bleConnectionProvider, (_, next) {
        if (next.value == true) _hasConnected = true;
        if (_hasConnected && next.value == false && mounted) {
          showConnectionErrorModal(
            context,
            onRetry: () => ref.read(bleTelemetryServiceProvider).reconnect(),
            onReconfigureRole: () =>
                Navigator.pushReplacementNamed(context, '/role-selection'),
          );
        }
      });
    }

    final telemetry = widget.isControllerEngine
        ? ref.watch(liveTelemetryProvider)
        : ref.watch(bleTelemetryProvider).value;
    final settings = ref.watch(displaySettingsProvider);
    final controllerState =
        widget.isControllerEngine ? ref.watch(odometerProvider) : null;
    final direction = controllerState?.direction ??
        OdometerDirection.values.firstWhere(
          (value) => value.name == telemetry?.direction,
          orElse: () => OdometerDirection.forward,
        );
    final currentTime = ref.watch(currentTimeProvider).value ??
        DateTime.now().add(
          Duration(seconds: settings.rallyTimeOffsetSeconds),
        );

    final total = telemetry == null
        ? 0.0
        : (telemetry.isNavigatorDisplayHeld
            ? telemetry.navigatorHeldTotalDistance ?? telemetry.totalDistance
            : telemetry.totalDistance);
    final totalTime = formatRallyTime(
      telemetry != null &&
              telemetry.isNavigatorDisplayHeld &&
              telemetry.navigatorHeldTimestamp != null
          ? telemetry.navigatorHeldTimestamp!.add(
              Duration(seconds: settings.rallyTimeOffsetSeconds),
            )
          : currentTime,
      settings.isDecimalMinutes,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: telemetry == null
            ? const BleConnectionDiagnostics()
            : Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _telemetryArea(
                            telemetry: telemetry,
                            totalDistance: total,
                            totalTime: totalTime,
                            isMetric: settings.isMetric,
                            bumpAmount: settings.bumpAmount,
                            requiresDoubleTap: settings.bumpRequireDoubleTap,
                            isDecimalMinutes: settings.isDecimalMinutes,
                            currentTime: currentTime,
                          ),
                        ),
                        const VerticalDivider(color: Colors.white24, width: 1),
                        Expanded(
                          child: _controlArea(
                            telemetry: telemetry,
                            direction: direction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _telemetryArea({
    required LiveTelemetry telemetry,
    required double totalDistance,
    required String totalTime,
    required bool isMetric,
    required double bumpAmount,
    required bool requiresDoubleTap,
    required bool isDecimalMinutes,
    required DateTime currentTime,
  }) {
    final unit = isMetric ? 'km' : 'mi';
    final distanceScale = isMetric ? 1000.0 : 1609.344;
    final color = const Color(0xFF00FF00);
    final intervalColor = const Color(0xFFFFFF00);
    return Column(
      children: [
        Expanded(
          child: _odometerSection(
            label: 'TOTAL ($unit)',
            value: totalDistance / distanceScale,
            color: color,
            time: totalTime,
            accuracy: telemetry.gpsAccuracy,
            trailing: _bumpButton(
              label: 'BUMP+',
              step:
                  '${bumpAmount.toStringAsFixed(3)} ${isMetric ? 'KM' : 'MI'}',
              isPositive: true,
              requiresDoubleTap: requiresDoubleTap,
            ),
            trailingAlignment: Alignment.bottomCenter,
            onValueTap: () => _editMileage(
              isTotal: true,
              meters: totalDistance,
              isMetric: isMetric,
            ),
          ),
        ),
        _speedDivider(telemetry.speed, isMetric),
        Expanded(
          child: _odometerSection(
            label: 'INTERVAL ($unit)',
            value: telemetry.intervalDistance / distanceScale,
            color: intervalColor,
            time: formatRallyTime(currentTime, isDecimalMinutes),
            trailing: _bumpButton(
              label: 'BUMP-',
              step:
                  '${bumpAmount.toStringAsFixed(3)} ${isMetric ? 'KM' : 'MI'}',
              isPositive: false,
              requiresDoubleTap: requiresDoubleTap,
            ),
            trailingAlignment: Alignment.topCenter,
            onValueTap: () => _editMileage(
              isTotal: false,
              meters: telemetry.intervalDistance,
              isMetric: isMetric,
            ),
          ),
        ),
      ],
    );
  }

  Widget _odometerSection({
    required String label,
    required double value,
    required Color color,
    required String time,
    double? accuracy,
    Widget? trailing,
    Alignment? trailingAlignment,
    VoidCallback? onValueTap,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (accuracy != null) ...[
                        GpsSatelliteIcon(accuracy: accuracy),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        time,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Courier',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onValueTap,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      value.toStringAsFixed(3),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 140,
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (trailing != null) const SizedBox(width: 116),
                    ],
                  ),
                ),
              ],
            ),
            if (trailing != null)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 116,
                child: Align(
                  alignment: trailingAlignment ?? Alignment.center,
                  child: trailing,
                ),
              ),
          ],
        ),
      );

  Widget _speedDivider(double speed, bool isMetric) => Container(
        width: double.infinity,
        height: 38,
        decoration: const BoxDecoration(
          border:
              Border.symmetric(horizontal: BorderSide(color: Colors.white24)),
        ),
        alignment: Alignment.center,
        child: Text(
          'SPEED: ${(speed * (isMetric ? 3.6 : 2.236936)).round()} ${isMetric ? 'KPH' : 'MPH'}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _bumpButton({
    required String label,
    required String step,
    required bool isPositive,
    required bool requiresDoubleTap,
  }) {
    void apply() => _send(
          isPositive
              ? ControllerCommandOpcode.bumpPlus
              : ControllerCommandOpcode.bumpMinus,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: requiresDoubleTap ? null : apply,
      onDoubleTap: requiresDoubleTap ? apply : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
          if (requiresDoubleTap)
            Positioned(
              top: -7,
              right: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'x2',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controlArea({
    required LiveTelemetry telemetry,
    required OdometerDirection direction,
  }) =>
      Container(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _fprButton('FORWARD', OdometerDirection.forward, direction),
                  _fprButton('PARK', OdometerDirection.park, direction),
                  _fprButton('REVERSE', OdometerDirection.reverse, direction),
                ],
              ),
            ),
            const VerticalDivider(color: Colors.white24, width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Column(children: [
                      _actionButton(
                        telemetry.isNavigatorDisplayHeld ? 'RELEASE' : 'HOLD',
                        Colors.green,
                        () {
                          if (widget.isControllerEngine) {
                            final notifier = ref.read(
                              navigatorDisplayHoldProvider.notifier,
                            );
                            if (telemetry.isNavigatorDisplayHeld) {
                              notifier.release();
                            } else {
                              notifier.hold(
                                totalDistance: telemetry.totalDistance,
                                timestamp: DateTime.now(),
                              );
                            }
                          } else {
                            _send(ControllerCommandOpcode.toggleHold);
                          }
                        },
                      ),
                      _actionButton(
                        'RESET',
                        Colors.grey[850]!,
                        () => _send(ControllerCommandOpcode.resetTotal),
                      ),
                    ]),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Expanded(
                    child: Column(children: [
                      _actionButton(
                        'RESET',
                        Colors.grey[850]!,
                        () => _send(ControllerCommandOpcode.resetInterval),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: SharedOverflowPopupMenuButton(
                              isControllerEngine: widget.isControllerEngine,
                              icon: Icons.settings,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _fprButton(
    String label,
    OdometerDirection value,
    OdometerDirection activeDirection,
  ) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    activeDirection == value ? Colors.green : Colors.grey[850],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              onPressed: () => _send(
                ControllerCommandOpcode.setFprState,
                stringValue: value.name,
              ),
              child: FittedBox(child: Text(label)),
            ),
          ),
        ),
      );

  Widget _actionButton(String label, Color color, VoidCallback onPressed) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              onPressed: onPressed,
              child: FittedBox(child: Text(label)),
            ),
          ),
        ),
      );
}
