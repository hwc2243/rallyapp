import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rally_lib/rally_lib.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
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
                const Text('DEVICE ROLE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<DeviceRole>(
                  segments: const [
                    ButtonSegment(
                        value: DeviceRole.controller,
                        label: Text('Controller')),
                    ButtonSegment(
                        value: DeviceRole.driver, label: Text('Driver')),
                    ButtonSegment(
                        value: DeviceRole.navigator, label: Text('Navigator')),
                  ],
                  selected: {role},
                  onSelectionChanged: (value) async {
                    await ref
                        .read(deviceRoleProvider.notifier)
                        .setRole(value.first);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 24),
                if (role == DeviceRole.controller) ...[
                  _ControllerAdvertisingDiagnostics(service: service),
                  const SizedBox(height: 24),
                  const Text('BLE BROADCAST RATE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 5, label: Text('5 Hz')),
                      ButtonSegment(value: 10, label: Text('10 Hz')),
                      ButtonSegment(value: 20, label: Text('20 Hz')),
                    ],
                    selected: {service.frequencyHz},
                    onSelectionChanged: (value) =>
                        service.setFrequency(value.first),
                  ),
                ] else ...[
                  const Text('PAIR CONTROLLER',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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

class _ControllerAdvertisingDiagnostics extends StatelessWidget {
  const _ControllerAdvertisingDiagnostics({required this.service});

  final BleTelemetryService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ControllerBleStatus>(
      stream: service.controllerStatus,
      initialData: service.controllerStatusSnapshot,
      builder: (context, snapshot) {
        final status = snapshot.data ?? service.controllerStatusSnapshot;
        final error = status.error;
        final advertisingText = status.isAdvertising
            ? 'Advertising as RallyController'
            : error == null
                ? 'Starting Controller advertisement…'
                : 'Advertising failed';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTROLLER BLE STATUS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      status.isAdvertising
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color:
                          status.isAdvertising ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(advertisingText)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bluetooth radio: ${status.bluetoothPoweredOn ? 'ON' : 'WAITING / OFF'}',
                ),
                const Text('Service: 0000FA10-0000-1000-8000-00805F9B34FB'),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: service.restartControllerAdvertising,
                  icon: const Icon(Icons.refresh),
                  label: const Text('RESTART ADVERTISING'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControllerScanList extends StatefulWidget {
  const _ControllerScanList({required this.service});
  final BleTelemetryService service;

  @override
  State<_ControllerScanList> createState() => _ControllerScanListState();
}

class _ControllerScanListState extends State<_ControllerScanList> {
  Stream<List<BleControllerDevice>>? _scanStream;
  String? _error;
  bool _isRequestingPermission = false;
  int _scanRequestId = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startScan() async {
    final requestId = ++_scanRequestId;
    setState(() {
      _error = null;
      _isRequestingPermission = true;
      _scanStream = null;
    });
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
        if (!statuses.values.every((status) => status.isGranted)) {
          if (!mounted || requestId != _scanRequestId) return;
          setState(() {
            _isRequestingPermission = false;
            _error =
                'Nearby devices permission is required to scan and connect. Enable it in Android Settings, then retry.';
          });
          return;
        }
      }
      if (!mounted || requestId != _scanRequestId) return;
      setState(() {
        _isRequestingPermission = false;
        _scanStream = widget.service.scanForControllerDevices();
      });
    } catch (error) {
      if (!mounted || requestId != _scanRequestId) return;
      setState(() {
        _isRequestingPermission = false;
        _error = 'Unable to request Bluetooth permission: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BleControllerDevice>>(
      stream: _scanStream,
      builder: (context, snapshot) {
        final error = _error ?? snapshot.error?.toString();
        if (error != null) return _scanError(error);
        if (_isRequestingPermission) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Requesting Android Nearby devices permission…'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY'),
                    ),
                    OutlinedButton.icon(
                      onPressed: openAppSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('OPEN SETTINGS'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        final devices = snapshot.data ?? const <BleControllerDevice>[];
        if (devices.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _scanStream == null
                        ? 'Grant Nearby devices access, then scan for Rally Controllers.'
                        : 'Scanning for Rally Controllers…',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _scanStream == null ? 'GRANT & SCAN' : 'SCAN AGAIN',
                    ),
                  ),
                  if (_scanStream == null)
                    TextButton.icon(
                      onPressed: openAppSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('OPEN ANDROID SETTINGS'),
                    ),
                ],
              ),
            ),
          );
        }
        return Column(children: [
          for (final device in devices)
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(device.name),
              subtitle: Text('${device.id}  •  ${device.rssi} dBm'),
              onTap: () async {
                try {
                  await widget.service.pairControllerId(device.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (!mounted) return;
                  setState(() => _error = 'Connection failed: $error');
                }
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('SCAN AGAIN'),
            ),
          ),
        ]);
      },
    );
  }

  Widget _scanError(String error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY SCAN'),
            ),
            TextButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('OPEN ANDROID SETTINGS'),
            ),
          ],
        ),
      );
}
