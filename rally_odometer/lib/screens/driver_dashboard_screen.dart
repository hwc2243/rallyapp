import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../providers/rally_time_offset_provider.dart';
import '../widgets/ble_connection_diagnostics.dart';
import '../widgets/connection_error_modal.dart';
import '../widgets/shared_overflow_popup_menu_button.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({
    super.key,
    required this.isControllerEngine,
  });

  /// Uses local Controller telemetry when true; otherwise uses BLE telemetry.
  final bool isControllerEngine;
  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _hasConnected = false;

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
    final currentTime = ref.watch(currentTimeProvider).value ??
        DateTime.now().add(
          Duration(seconds: settings.rallyTimeOffsetSeconds),
        );
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: [
              _header(telemetry?.gpsAccuracy ?? 0, showBluetoothController),
              Expanded(
                child: telemetry == null
                    ? const BleConnectionDiagnostics()
                    : _dashboardGrid(
                        telemetry,
                        settings.isMetric,
                        settings.isDecimalMinutes,
                        currentTime,
                      ),
              ),
            ]),
            Positioned(
              right: 8,
              bottom: 8,
              child: SharedOverflowPopupMenuButton(
                isControllerEngine: widget.isControllerEngine,
                icon: Icons.settings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(double accuracy, bool showBluetoothController) => Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GpsSatelliteIcon(accuracy: accuracy),
            if (showBluetoothController) ...[
              const SizedBox(width: 8),
              const Icon(Icons.bluetooth, color: Colors.lightBlueAccent),
            ],
          ],
        ),
      );

  Widget _dashboardGrid(
    LiveTelemetry telemetry,
    bool isMetric,
    bool isDecimalMinutes,
    DateTime currentTime,
  ) {
    final speed = telemetry.speed * (isMetric ? 3.6 : 2.236936);
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, right: 60, bottom: 12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _distancePanel(
                    'TOTAL',
                    telemetry.totalDistance,
                    isMetric,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _valuePanel(
                    'SPEED (${isMetric ? 'KPH' : 'MPH'})',
                    '${speed.round()}',
                    Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _distancePanel(
                    'INTERVAL',
                    telemetry.intervalDistance,
                    isMetric,
                    Colors.yellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _valuePanel(
                    'TIME',
                    formatRallyTime(currentTime, isDecimalMinutes),
                    Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _distancePanel(
    String label,
    double meters,
    bool metric,
    Color color,
  ) =>
      _valuePanel(
        '$label (${metric ? 'km' : 'mi'})',
        (meters / (metric ? 1000.0 : 1609.344)).toStringAsFixed(3),
        color,
      );

  Widget _valuePanel(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 130,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

class GpsSatelliteIcon extends StatelessWidget {
  const GpsSatelliteIcon({super.key, required this.accuracy});

  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final color = accuracy == 0
        ? Colors.grey
        : accuracy < 10
            ? Colors.green
            : accuracy <= 15
                ? Colors.yellow
                : Colors.red;
    return Icon(Icons.satellite_alt, color: color, size: 28);
  }
}
