import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

/// Visible only while a remote dashboard is waiting for its Controller.
class BleConnectionDiagnostics extends ConsumerWidget {
  const BleConnectionDiagnostics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(bleTelemetryServiceProvider);
    return StreamBuilder<BleConnectionDiagnostic>(
      stream: service.connectionDiagnostics,
      initialData: service.connectionDiagnosticSnapshot,
      builder: (context, snapshot) {
        final diagnostic =
            snapshot.data ?? service.connectionDiagnosticSnapshot;
        final text = diagnostic.displayText;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bluetooth_searching, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'CONTROLLER CONNECTION DIAGNOSTICS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Courier'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: service.reconnect,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/role-selection',
                      ),
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('PAIR CONTROLLER'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('BLE diagnostics copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('COPY'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
