import 'package:material_ui/material_ui.dart';
import 'package:rally_lib/rally_lib.dart';

/// Displays the required stationary and drive-forward steps while
/// PrecisionDrive learns the current vehicle mount.
class PrecisionDriveCalibrationGate extends StatelessWidget {
  const PrecisionDriveCalibrationGate({
    super.key,
    required this.sensorFusion,
    required this.child,
  });

  final SensorFusionService sensorFusion;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: sensorFusion.orientation,
    builder: (context, _) {
      final state = sensorFusion.orientation.value;
      final showCalibration =
          state.status != PrecisionDriveOrientationStatus.idle &&
          state.needsCalibration;
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (showCalibration)
            _CalibrationOverlay(
              state: state,
              onContinue: sensorFusion.beginCalibration,
            ),
        ],
      );
    },
  );
}

class _CalibrationOverlay extends StatelessWidget {
  const _CalibrationOverlay({required this.state, required this.onContinue});

  final PrecisionDriveOrientationState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final awaiting =
        state.status == PrecisionDriveOrientationStatus.awaitingConfirmation;
    final stationary =
        state.status == PrecisionDriveOrientationStatus.calibratingStationary;
    final message = awaiting
        ? 'Mount the phone in its normal position. After Continue, keep the vehicle still for a few seconds, then drive forward in a straight line.'
        : stationary
        ? 'Hold the vehicle still while PrecisionDrive learns the phone orientation.'
        : 'Drive forward in a straight line so PrecisionDrive can learn the vehicle direction.';
    return Material(
      color: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stationary ? Icons.sensors : Icons.directions_car_filled,
                    color: const Color(0xFF55B7FF),
                    size: 96,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Calibrating PrecisionDrive Assist',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    awaiting
                        ? 'PrecisionDrive will finish once it receives both a GPS course and a compass heading while you drive forward.'
                        : stationary
                        ? 'This normally takes a couple of seconds.'
                        : 'This screen closes automatically when a GPS course is available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.3,
                    ),
                  ),
                  if (awaiting) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
