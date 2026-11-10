import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

const _calibrationPreferenceKey = 'rallymasterPrecisionDriveCalibration';

/// Blocks planning until PrecisionDrive has a calibration for the current
/// vehicle mount, and stores a completed calibration for later planning runs.
class PrecisionDriveCalibrationGate extends ConsumerStatefulWidget {
  const PrecisionDriveCalibrationGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrecisionDriveCalibrationGate> createState() =>
      _PrecisionDriveCalibrationGateState();
}

class _PrecisionDriveCalibrationGateState
    extends ConsumerState<PrecisionDriveCalibrationGate> {
  late final SensorFusionService _sensorFusion;

  @override
  void initState() {
    super.initState();
    _sensorFusion = ref.read(sensorFusionServiceProvider);
    _sensorFusion.orientation.addListener(_persistCompletedCalibration);
  }

  @override
  void dispose() {
    _sensorFusion.orientation.removeListener(_persistCompletedCalibration);
    super.dispose();
  }

  void _persistCompletedCalibration() {
    final profile = _sensorFusion.calibrationProfile;
    if (profile == null) return;
    ref
        .read(sharedPreferencesProvider)
        .setString(_calibrationPreferenceKey, jsonEncode(profile.toJson()));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _sensorFusion.orientation,
    builder: (context, _) {
      final state = _sensorFusion.orientation.value;
      final shouldShow =
          state.status != PrecisionDriveOrientationStatus.idle &&
          state.needsCalibration;
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (shouldShow)
            _CalibrationOverlay(
              state: state,
              onContinue: _sensorFusion.beginCalibration,
            ),
        ],
      );
    },
  );
}

/// Loads a saved calibration profile, returning false when planning must be
/// calibrated before PrecisionDrive can assist.
Future<bool> restorePrecisionDriveCalibration(WidgetRef ref) async {
  final raw = ref
      .read(sharedPreferencesProvider)
      .getString(_calibrationPreferenceKey);
  if (raw == null) return false;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return false;
    final profile = PrecisionDriveCalibrationProfile.fromJson(decoded);
    if (profile == null) return false;
    ref.read(sensorFusionServiceProvider).restoreCalibrationProfile(profile);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> clearPrecisionDriveCalibration(WidgetRef ref) async {
  await ref.read(sharedPreferencesProvider).remove(_calibrationPreferenceKey);
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
                    awaiting
                        ? 'Mount the phone in its normal position. After Continue, keep the vehicle still for a few seconds, then drive forward in a straight line.'
                        : stationary
                        ? 'Hold the vehicle still while PrecisionDrive learns the phone orientation.'
                        : 'Drive forward in a straight line so PrecisionDrive can learn the vehicle direction.',
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
                        ? 'PrecisionDrive finishes once it receives both a GPS course and a compass heading while you drive forward.'
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
