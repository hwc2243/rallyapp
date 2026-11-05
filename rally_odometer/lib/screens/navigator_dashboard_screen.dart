import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:rallymaster_ui/rallymaster_ui.dart';

import '../providers/rally_time_offset_provider.dart';
import '../widgets/ble_connection_diagnostics.dart';
import '../widgets/connection_error_modal.dart';
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
        case ControllerCommandOpcode.setSensorFusionEnabled:
        case ControllerCommandOpcode.setSensorFusionAccuracyThresholdMeters:
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
    final showBluetoothController = widget.isControllerEngine &&
        ref.watch(bluetoothControllerEnabledProvider);
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
            : Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: MediaQuery.orientationOf(context) ==
                                Orientation.portrait
                            ? _portraitDashboard(
                                telemetry: telemetry,
                                totalDistance: total,
                                totalTime: totalTime,
                                isMetric: settings.isMetric,
                                bumpAmount: settings.bumpAmount,
                                requiresDoubleTap:
                                    settings.bumpRequireDoubleTap,
                                isDecimalMinutes: settings.isDecimalMinutes,
                                currentTime: currentTime,
                                direction: direction,
                                showBluetoothController:
                                    showBluetoothController,
                              )
                            : _landscapeDashboard(
                                telemetry: telemetry,
                                totalDistance: total,
                                totalTime: totalTime,
                                isMetric: settings.isMetric,
                                bumpAmount: settings.bumpAmount,
                                requiresDoubleTap:
                                    settings.bumpRequireDoubleTap,
                                isDecimalMinutes: settings.isDecimalMinutes,
                                currentTime: currentTime,
                                direction: direction,
                                showBluetoothController:
                                    showBluetoothController,
                              ),
                      ),
                    ],
                  ),
                  if (telemetry.isCalibrating)
                    const Positioned.fill(child: CalibrationOverlay()),
                ],
              ),
      ),
    );
  }

  /// Dedicated portrait composition. The landscape telemetry/control columns
  /// remain unchanged in [_telemetryArea] and [_controlArea].
  Widget _portraitDashboard({
    required LiveTelemetry telemetry,
    required double totalDistance,
    required String totalTime,
    required bool isMetric,
    required double bumpAmount,
    required bool requiresDoubleTap,
    required bool isDecimalMinutes,
    required DateTime currentTime,
    required OdometerDirection direction,
    required bool showBluetoothController,
  }) {
    final unit = isMetric ? 'km' : 'mi';
    final distanceScale = isMetric ? 1000.0 : 1609.344;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: _portraitIndicators(
              accuracy: telemetry.gpsAccuracy,
              isSensorFusionActive: telemetry.isSensorFusionActive,
              showBluetoothController: showBluetoothController,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: _portraitOdometerSection(
              label: 'TOTAL ($unit)',
              value: totalDistance / distanceScale,
              color: const Color(0xFF00FF00),
              time: totalTime,
              onValueTap: () => _editMileage(
                isTotal: true,
                meters: totalDistance,
                isMetric: isMetric,
              ),
              controls: Column(
                children: [
                  Expanded(child: _holdButton(telemetry)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _portraitActionButton(
                      'RESET',
                      Colors.grey[850]!,
                      () => _send(ControllerCommandOpcode.resetTotal),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 68,
            child: Row(
              children: [
                _portraitFprButton(
                  'FORWARD',
                  OdometerDirection.forward,
                  direction,
                ),
                _portraitFprButton(
                  'PARK',
                  OdometerDirection.park,
                  direction,
                ),
                _portraitFprButton(
                  'REVERSE',
                  OdometerDirection.reverse,
                  direction,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: _portraitOdometerSection(
              label: 'INTERVAL ($unit)',
              value: telemetry.intervalDistance / distanceScale,
              color: const Color(0xFFFFFF00),
              time: formatRallyTime(currentTime, isDecimalMinutes),
              onValueTap: () => _editMileage(
                isTotal: false,
                meters: telemetry.intervalDistance,
                isMetric: isMetric,
              ),
              controls: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _portraitActionButton(
                      'RESET',
                      Colors.grey[850]!,
                      () => _send(ControllerCommandOpcode.resetInterval),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _speedDivider(telemetry.speed, isMetric),
          const SizedBox(height: 6),
          SizedBox(
            height: 68,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _bumpButton(
                        label: 'BUMP-',
                        step:
                            '${bumpAmount.toStringAsFixed(3)} ${isMetric ? 'KM' : 'MI'}',
                        isPositive: false,
                        requiresDoubleTap: requiresDoubleTap,
                      ),
                      const SizedBox(width: 8),
                      _bumpButton(
                        label: 'BUMP+',
                        step:
                            '${bumpAmount.toStringAsFixed(3)} ${isMetric ? 'KM' : 'MI'}',
                        isPositive: true,
                        requiresDoubleTap: requiresDoubleTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _portraitIndicators({
    required double accuracy,
    required bool isSensorFusionActive,
    required bool showBluetoothController,
  }) =>
      Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GpsSatelliteIcon(
                accuracy: accuracy,
                isSensorFusionActive: isSensorFusionActive,
              ),
              if (showBluetoothController) ...[
                const SizedBox(width: 8),
                const Icon(Icons.bluetooth, color: Colors.lightBlueAccent),
              ],
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            // PopupMenuButton retains a 48dp touch target, whose visual icon
            // sits slightly low in this compact 30dp status header. Keep the
            // full touch target but align the visible gear with GPS.
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: SharedOverflowPopupMenuButton(
                isControllerEngine: widget.isControllerEngine,
                icon: Icons.settings,
              ),
            ),
          ),
        ],
      );

  Widget _portraitOdometerSection({
    required String label,
    required double value,
    required Color color,
    required String time,
    required Widget controls,
    VoidCallback? onValueTap,
  }) =>
      Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onValueTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              time,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: color,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value.toStringAsFixed(3),
                              style: TextStyle(
                                color: color,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 100,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 86,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: controls,
              ),
            ),
          ],
        ),
      );

  Widget _holdButton(LiveTelemetry telemetry) => _portraitActionButton(
        telemetry.isNavigatorDisplayHeld ? 'RELEASE' : 'HOLD',
        telemetry.isNavigatorDisplayHeld ? Colors.amber : Colors.green,
        () {
          if (widget.isControllerEngine) {
            final notifier = ref.read(navigatorDisplayHoldProvider.notifier);
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
        flash: telemetry.isNavigatorDisplayHeld,
      );

  Widget _portraitActionButton(
    String label,
    Color color,
    VoidCallback onPressed, {
    bool flash = false,
  }) =>
      SizedBox.expand(
        child: _PulsingButton(
          pulse: flash,
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
      );

  Widget _portraitFprButton(
    String label,
    OdometerDirection value,
    OdometerDirection activeDirection,
  ) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox.expand(
            child: _PulsingButton(
              pulse: activeDirection == value &&
                  value != OdometerDirection.forward,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeDirection == value
                      ? (value == OdometerDirection.forward
                          ? Colors.green
                          : Colors.red)
                      : Colors.grey[850],
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
        ),
      );

  /// Landscape keeps the Navigator's familiar telemetry/control columns while
  /// reserving an unshared status row for GPS and the app menu. This prevents
  /// the top-right menu from competing with the Hold control.
  Widget _landscapeDashboard({
    required LiveTelemetry telemetry,
    required double totalDistance,
    required String totalTime,
    required bool isMetric,
    required double bumpAmount,
    required bool requiresDoubleTap,
    required bool isDecimalMinutes,
    required DateTime currentTime,
    required OdometerDirection direction,
    required bool showBluetoothController,
  }) =>
      Column(
        children: [
          _landscapeStatusHeader(
            accuracy: telemetry.gpsAccuracy,
            isSensorFusionActive: telemetry.isSensorFusionActive,
            showBluetoothController: showBluetoothController,
            time: totalTime,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _telemetryArea(
                    telemetry: telemetry,
                    totalDistance: totalDistance,
                    totalTime: totalTime,
                    isMetric: isMetric,
                    bumpAmount: bumpAmount,
                    requiresDoubleTap: requiresDoubleTap,
                    isDecimalMinutes: isDecimalMinutes,
                    currentTime: currentTime,
                    showBluetoothController: showBluetoothController,
                    showOdometerHeaders: false,
                    showSpeedDivider: false,
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
          _speedDivider(telemetry.speed, isMetric),
        ],
      );

  Widget _landscapeStatusHeader({
    required double accuracy,
    required bool isSensorFusionActive,
    required bool showBluetoothController,
    required String time,
  }) =>
      Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white24)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GpsSatelliteIcon(
                  accuracy: accuracy,
                  isSensorFusionActive: isSensorFusionActive,
                ),
                if (showBluetoothController) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.bluetooth, color: Colors.lightBlueAccent),
                ],
                const SizedBox(width: 12),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SharedOverflowPopupMenuButton(
                isControllerEngine: widget.isControllerEngine,
                icon: Icons.settings,
              ),
            ),
          ],
        ),
      );

  Widget _telemetryArea({
    required LiveTelemetry telemetry,
    required double totalDistance,
    required String totalTime,
    required bool isMetric,
    required double bumpAmount,
    required bool requiresDoubleTap,
    required bool isDecimalMinutes,
    required DateTime currentTime,
    required bool showBluetoothController,
    bool showOdometerHeaders = true,
    bool showSpeedDivider = true,
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
            time: showOdometerHeaders ? totalTime : null,
            accuracy: showOdometerHeaders ? telemetry.gpsAccuracy : null,
            isSensorFusionActive:
                showOdometerHeaders && telemetry.isSensorFusionActive,
            showBluetoothController:
                showOdometerHeaders && showBluetoothController,
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
        if (showSpeedDivider)
          _speedDivider(telemetry.speed, isMetric)
        else
          const Divider(color: Colors.white24, height: 1),
        Expanded(
          child: _odometerSection(
            label: 'INTERVAL ($unit)',
            value: telemetry.intervalDistance / distanceScale,
            color: intervalColor,
            time: showOdometerHeaders
                ? formatRallyTime(currentTime, isDecimalMinutes)
                : null,
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
    String? time,
    double? accuracy,
    bool isSensorFusionActive = false,
    bool showBluetoothController = false,
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
                if (time != null)
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (accuracy != null) ...[
                          GpsSatelliteIcon(
                            accuracy: accuracy,
                            isSensorFusionActive: isSensorFusionActive,
                          ),
                          if (showBluetoothController) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.bluetooth,
                              color: Colors.lightBlueAccent,
                            ),
                          ],
                          const SizedBox(width: 8),
                          SharedOverflowPopupMenuButton(
                            isControllerEngine: widget.isControllerEngine,
                            icon: Icons.settings,
                          ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Center(
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
                              ),
                            ],
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
                        telemetry.isNavigatorDisplayHeld
                            ? Colors.amber
                            : Colors.green,
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
                        flash: telemetry.isNavigatorDisplayHeld,
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
                      const Spacer(),
                      _actionButton(
                        'RESET',
                        Colors.grey[850]!,
                        () => _send(ControllerCommandOpcode.resetInterval),
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
            child: _PulsingButton(
              pulse: activeDirection == value &&
                  value != OdometerDirection.forward,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeDirection == value
                      ? (value == OdometerDirection.forward
                          ? Colors.green
                          : Colors.red)
                      : Colors.grey[850],
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
        ),
      );

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback onPressed, {
    bool flash = false,
  }) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: double.infinity,
            child: _PulsingButton(
              pulse: flash,
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
        ),
      );
}

/// Pulses a warning control for as long as its corresponding state is active.
class _PulsingButton extends StatefulWidget {
  const _PulsingButton({required this.pulse, required this.child});

  final bool pulse;
  final Widget child;

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulsingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
        child: widget.child,
      );
}
