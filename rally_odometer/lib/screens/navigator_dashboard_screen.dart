import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../widgets/connection_error_modal.dart';

/// Remote counterpart to the Controller dashboard. Every control writes a
/// command packet; it never mutates local odometer state.
class NavigatorDashboardScreen extends ConsumerStatefulWidget {
  const NavigatorDashboardScreen({super.key});
  @override
  ConsumerState<NavigatorDashboardScreen> createState() => _NavigatorDashboardScreenState();
}

class _NavigatorDashboardScreenState extends ConsumerState<NavigatorDashboardScreen> {
  bool _hasConnected = false;
  double? _heldTotal;

  void _send(ControllerCommandOpcode opcode, {double? value, String? text}) {
    ref.read(bleTelemetryServiceProvider).sendCommand(ControllerCommand(
      opcode: opcode, numericValue: value, stringValue: text, timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(bleConnectionProvider, (_, next) {
      if (next.value == true) _hasConnected = true;
      if (_hasConnected && next.value == false && mounted) {
        showConnectionErrorModal(
          context,
          onRetry: () => ref.read(bleTelemetryServiceProvider).reconnect(),
          onReconfigureRole: () => Navigator.pushReplacementNamed(context, '/role-selection'),
        );
      }
    });
    final telemetry = ref.watch(bleTelemetryProvider).value;
    final settings = ref.watch(settingsProvider);
    if (telemetry != null && !telemetry.isDisplayHeld) _heldTotal = null;
    if (telemetry != null && telemetry.isDisplayHeld) _heldTotal ??= telemetry.totalDistance;
    final total = telemetry == null ? 0.0 : (telemetry.isDisplayHeld ? _heldTotal! : telemetry.totalDistance);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Row(children: [
        Expanded(child: telemetry == null ? const Center(child: CircularProgressIndicator()) : Column(children: [
          Expanded(child: _display('TOTAL', total, settings.isMetric, Colors.green)),
          _speed(telemetry.speed, telemetry.gpsAccuracy, settings.isMetric),
          Expanded(child: _display('INTERVAL', telemetry.intervalDistance, settings.isMetric, Colors.yellow)),
        ])),
        SizedBox(width: MediaQuery.of(context).size.width * .20, child: _controls(telemetry, settings)),
      ])),
    );
  }

  Widget _display(String label, double meters, bool metric, Color color) => Padding(
    padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label (${metric ? 'km' : 'mi'})', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      Expanded(child: Center(child: FittedBox(child: Text((meters / (metric ? 1000 : 1609.344)).toStringAsFixed(3), style: TextStyle(color: color, fontSize: 130, fontFamily: 'Courier', fontWeight: FontWeight.bold))))),
    ]),
  );

  Widget _speed(double speed, double accuracy, bool metric) => Padding(
    padding: const EdgeInsets.all(8), child: Text('SPD: ${(speed * (metric ? 3.6 : 2.236936)).round()}  ACC: ±${accuracy.toStringAsFixed(1)}m', style: const TextStyle(color: Colors.white, fontFamily: 'Courier')),
  );

  Widget _controls(LiveTelemetry? telemetry, OdometerSettings settings) => Container(
    padding: const EdgeInsets.all(6), decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.white24))),
    child: Column(children: [
      _button(telemetry?.isDisplayHeld == true ? 'RELEASE' : 'HOLD', Colors.green, () => _send(ControllerCommandOpcode.toggleHold)),
      _button('RESET TOTAL', Colors.grey, () => _send(ControllerCommandOpcode.resetTotal)),
      _button('BUMP +', Colors.blueGrey, () => _send(ControllerCommandOpcode.bumpPlus)),
      _button('BUMP -', Colors.blueGrey, () => _send(ControllerCommandOpcode.bumpMinus)),
      _button('RESET INT', Colors.grey, () => _send(ControllerCommandOpcode.resetInterval)),
      _button('FORWARD', Colors.green, () => _send(ControllerCommandOpcode.setFprState, text: OdometerDirection.forward.name)),
      _button('PARK', Colors.white, () => _send(ControllerCommandOpcode.setFprState, text: OdometerDirection.park.name)),
      _button('REVERSE', Colors.red, () => _send(ControllerCommandOpcode.setFprState, text: OdometerDirection.reverse.name)),
      PopupMenuButton<String>(icon: const Icon(Icons.menu, color: Colors.white), onSelected: (value) => Navigator.pushNamed(context, value), itemBuilder: (_) => const [
        PopupMenuItem(value: '/settings', child: Text('Settings')), PopupMenuItem(value: '/details', child: Text('Details')),
      ]),
    ]),
  );

  Widget _button(String text, Color color, VoidCallback onPressed) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 2), child: SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: color == Colors.white ? Colors.black : Colors.white), onPressed: onPressed, child: FittedBox(child: Text(text)))),
  ));
}
