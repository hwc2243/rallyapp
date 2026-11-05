import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:rallymaster_ui/rallymaster_ui.dart';

/// Compact planning controls for the shared RallyLib odometer.
class PlanOdometerDialog extends ConsumerWidget {
  const PlanOdometerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final odometer = ref.watch(odometerProvider);
    final settings = ref.watch(settingsProvider);
    final miles = settings.isMetric
        ? odometer.totalDistance / 1000
        : odometer.totalDistance / 1609.344;
    final unit = settings.isMetric ? 'KM' : 'MI';
    final notifier = ref.read(odometerProvider.notifier);

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RALLY ODOMETER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    _editMileage(context, ref, miles, settings.isMetric),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TOTAL MILEAGE ($unit) — TAP TO ENTER',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          miles.toStringAsFixed(3),
                          style: const TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: notifier.resetTotal,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('RESET'),
                ),
              ),
              const SizedBox(height: 14),
              OdometerDirectionSelector(
                direction: odometer.direction,
                onChanged: notifier.setDirection,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OdometerBumpButton(
                      label: 'BUMP −',
                      amount: settings.bumpAmount,
                      unit: unit,
                      requireDoubleTap: settings.bumpRequireDoubleTap,
                      onPressed: () => notifier.applyBump(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OdometerBumpButton(
                      label: 'BUMP +',
                      amount: settings.bumpAmount,
                      unit: unit,
                      requireDoubleTap: settings.bumpRequireDoubleTap,
                      onPressed: () => notifier.applyBump(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMileage(
    BuildContext context,
    WidgetRef ref,
    double currentMileage,
    bool isMetric,
  ) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => MileageEntryDialog(
        initialValue: currentMileage.toStringAsFixed(3),
        title: 'SET TOTAL (${isMetric ? 'km' : 'mi'})',
      ),
    );
    if (value == null) return;
    ref
        .read(odometerProvider.notifier)
        .setTotalDistance(value * (isMetric ? 1000 : 1609.344));
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: active ? activeColor : Colors.transparent,
          side: BorderSide(color: active ? activeColor : Colors.white38),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}

class _BumpButton extends StatelessWidget {
  const _BumpButton({
    required this.label,
    required this.amount,
    required this.unit,
    required this.requireDoubleTap,
    required this.onPressed,
  });

  final String label;
  final double amount;
  final String unit;
  final bool requireDoubleTap;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: requireDoubleTap ? null : onPressed,
    onDoubleTap: requireDoubleTap ? onPressed : null,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AbsorbPointer(
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${amount.toStringAsFixed(3)} $unit',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (requireDoubleTap)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'x2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
