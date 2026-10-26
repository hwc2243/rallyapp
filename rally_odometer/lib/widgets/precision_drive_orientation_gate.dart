import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

/// Keeps PrecisionDrive Assist from operating until the phone is mounted flat
/// with its top aligned to the direction of travel.
class PrecisionDriveOrientationGate extends ConsumerWidget {
  const PrecisionDriveOrientationGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsProvider.select((settings) => settings.sensorFusionEnabled),
    );
    final available = ref.watch(
      settingsProvider.select((settings) => settings.precisionDriveAvailable),
    );
    final isController = ref.watch(deviceRoleProvider) == DeviceRole.controller;
    final sensorFusion = ref.read(sensorFusionServiceProvider);

    return AnimatedBuilder(
      animation: sensorFusion.orientation,
      builder: (context, _) {
        final mountState = sensorFusion.orientation.value;
        final shouldShow = enabled &&
            available &&
            isController &&
            mountState.status != PrecisionDriveOrientationStatus.idle &&
            mountState.needsCalibration;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (shouldShow)
              _PrecisionDriveOrientationScreen(
                state: mountState,
                onContinue: sensorFusion.beginCalibration,
                onDisable: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setSensorFusionEnabled(false);
                  sensorFusion.setEnabled(false);
                },
              ),
          ],
        );
      },
    );
  }
}

class _PrecisionDriveOrientationScreen extends StatelessWidget {
  const _PrecisionDriveOrientationScreen({
    required this.state,
    required this.onContinue,
    required this.onDisable,
  });

  final PrecisionDriveOrientationState state;
  final VoidCallback onContinue;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final isMountConfirmation =
        state.status == PrecisionDriveOrientationStatus.awaitingConfirmation;
    final isStationary =
        state.status == PrecisionDriveOrientationStatus.calibratingStationary;
    return Material(
      color: Colors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 600;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 24,
                vertical: compact ? 8 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 16 : 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isStationary
                              ? Icons.sensors
                              : Icons.directions_car_filled,
                          size: compact ? 64 : 132,
                          color: const Color(0xFF55B7FF),
                        ),
                        SizedBox(height: compact ? 8 : 24),
                        Text(
                          'Calibrating PrecisionDrive Assist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 20 : 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 12),
                        Text(
                          isMountConfirmation
                              ? 'Mount the phone in its normal position, then press Continue.'
                              : isStationary
                                  ? 'Hold the vehicle still while PrecisionDrive learns the phone orientation.'
                                  : 'Drive forward in a straight line so PrecisionDrive can learn the vehicle direction.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 15 : 19,
                            height: compact ? 1.2 : 1.35,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 12),
                        Text(
                          isMountConfirmation
                              ? 'Calibration uses this stationary mount position each time you drive.'
                              : isStationary
                                  ? 'This normally takes a couple of seconds.'
                                  : 'The calibration screen will close automatically when a GPS course is available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 13 : 15,
                            height: compact ? 1.2 : 1.35,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 28),
                        if (isMountConfirmation) ...[
                          FilledButton.icon(
                            onPressed: onContinue,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Continue'),
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(compact ? 38 : 48),
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 8 : 12,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 12),
                        ],
                        OutlinedButton.icon(
                          onPressed: onDisable,
                          icon: const Icon(Icons.power_settings_new),
                          label: const Text('Disable PrecisionDrive Assist'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: compact ? 8 : 14,
                            ),
                            minimumSize: Size.fromHeight(compact ? 38 : 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
