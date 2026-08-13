import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../widgets/connection_error_modal.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _hasConnected = false;

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          if (telemetry == null)
            const Center(child: CircularProgressIndicator())
          else
            Column(children: [
              Expanded(child: _distancePanel('TOTAL', telemetry.totalDistance, settings.isMetric, Colors.green)),
              _statusBar(telemetry.speed, telemetry.gpsAccuracy, settings.isMetric),
              Expanded(child: _distancePanel('INTERVAL', telemetry.intervalDistance, settings.isMetric, Colors.yellow)),
            ]),
          Positioned(
            right: 8, bottom: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              onSelected: (_) => Navigator.pushNamed(context, '/details'),
              itemBuilder: (_) => const [PopupMenuItem(value: 'details', child: Text('Details'))],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _distancePanel(String label, double meters, bool metric, Color color) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label (${metric ? 'km' : 'mi'})', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      Expanded(child: Center(child: FittedBox(child: Text(
        (meters / (metric ? 1000.0 : 1609.344)).toStringAsFixed(3),
        style: TextStyle(color: color, fontSize: 130, fontFamily: 'Courier', fontWeight: FontWeight.bold),
      )))),
    ]),
  );

  Widget _statusBar(double speed, double accuracy, bool metric) => Container(
    padding: const EdgeInsets.all(8),
    decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.white24))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Text('SPD: ${(speed * (metric ? 3.6 : 2.236936)).round()} ${metric ? 'km/h' : 'mph'}', style: const TextStyle(color: Colors.white, fontFamily: 'Courier')),
      Text('ACC: ±${accuracy.toStringAsFixed(1)}m', style: TextStyle(color: accuracy < 10 ? Colors.green : accuracy <= 15 ? Colors.yellow : Colors.red, fontFamily: 'Courier')),
    ]),
  );
}
