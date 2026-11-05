import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

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
              Row(
                children: [
                  _DirectionButton(
                    label: 'FORWARD',
                    active: odometer.direction == OdometerDirection.forward,
                    activeColor: Colors.green.shade700,
                    onPressed: () =>
                        notifier.setDirection(OdometerDirection.forward),
                  ),
                  const SizedBox(width: 8),
                  _DirectionButton(
                    label: 'PARK',
                    active: odometer.direction == OdometerDirection.park,
                    activeColor: Colors.red.shade800,
                    onPressed: () =>
                        notifier.setDirection(OdometerDirection.park),
                  ),
                  const SizedBox(width: 8),
                  _DirectionButton(
                    label: 'REVERSE',
                    active: odometer.direction == OdometerDirection.reverse,
                    activeColor: Colors.red.shade800,
                    onPressed: () =>
                        notifier.setDirection(OdometerDirection.reverse),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BumpButton(
                      label: 'BUMP −',
                      amount: settings.bumpAmount,
                      unit: unit,
                      onPressed: () => notifier.applyBump(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BumpButton(
                      label: 'BUMP +',
                      amount: settings.bumpAmount,
                      unit: unit,
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
      builder: (_) => _MileageEntryDialog(initialValue: currentMileage),
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
    required this.onPressed,
  });

  final String label;
  final double amount;
  final String unit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${amount.toStringAsFixed(3)} $unit',
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _MileageEntryDialog extends StatefulWidget {
  const _MileageEntryDialog({required this.initialValue});

  final double initialValue;

  @override
  State<_MileageEntryDialog> createState() => _MileageEntryDialogState();
}

class _MileageEntryDialogState extends State<_MileageEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.black,
    title: const Text(
      'Set total mileage',
      style: TextStyle(color: Colors.white),
    ),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: Color(0xFF00FF00),
        fontFamily: 'Courier',
        fontSize: 28,
      ),
      decoration: const InputDecoration(
        labelText: 'Mileage',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
      ),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Set')),
    ],
  );

  void _save() {
    final value = double.tryParse(_controller.text);
    if (value != null && value >= 0) Navigator.of(context).pop(value);
  }
}
