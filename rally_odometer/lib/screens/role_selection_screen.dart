import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../providers/controller_display_view_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    final controllerDisplayView = ref.watch(controllerDisplayViewProvider);
    final service = ref.watch(bleTelemetryServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('DEVICE ROLE & BLUETOOTH')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('DEVICE ROLE', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<DeviceRole>(
                  segments: const [
                    ButtonSegment(value: DeviceRole.controller, label: Text('Controller')),
                    ButtonSegment(value: DeviceRole.driver, label: Text('Driver')),
                    ButtonSegment(value: DeviceRole.navigator, label: Text('Navigator')),
                  ],
                  selected: {role},
                  onSelectionChanged: (value) async {
                    await ref.read(deviceRoleProvider.notifier).setRole(value.first);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 24),
                if (role == DeviceRole.controller) ...[
                  const Text('CONTROLLER DISPLAY VIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<ControllerDisplayView>(
                    segments: const [
                      ButtonSegment(
                        value: ControllerDisplayView.driver,
                        label: Text('Driver View'),
                      ),
                      ButtonSegment(
                        value: ControllerDisplayView.navigator,
                        label: Text('Navigator View'),
                      ),
                    ],
                    selected: {controllerDisplayView},
                    onSelectionChanged: (value) => ref
                        .read(controllerDisplayViewProvider.notifier)
                        .setView(value.first),
                  ),
                  const SizedBox(height: 24),
                  const Text('BLE BROADCAST RATE', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 5, label: Text('5 Hz')),
                      ButtonSegment(value: 10, label: Text('10 Hz')),
                      ButtonSegment(value: 20, label: Text('20 Hz')),
                    ],
                    selected: {service.frequencyHz},
                    onSelectionChanged: (value) => service.setFrequency(value.first),
                  ),
                ] else ...[
                  const Text('PAIR CONTROLLER', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _ControllerScanList(service: service),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControllerScanList extends StatelessWidget {
  const _ControllerScanList({required this.service});
  final BleTelemetryService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BleControllerDevice>>(
      stream: service.scanForControllerDevices(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <BleControllerDevice>[];
        if (devices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16), child: Center(child: Text('Scanning for Rally Controllers…')),
          );
        }
        return Column(children: [
          for (final device in devices)
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(device.name),
              subtitle: Text('${device.id}  •  ${device.rssi} dBm'),
              onTap: () async {
                await service.pairControllerId(device.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ]);
      },
    );
  }
}
