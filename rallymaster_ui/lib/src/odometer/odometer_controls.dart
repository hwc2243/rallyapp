import 'package:flutter/material.dart';
import 'package:rally_lib/rally_lib.dart';

/// A compact Forward, Park, and Reverse selector with a Rally Odometer style.
class OdometerDirectionSelector extends StatelessWidget {
  const OdometerDirectionSelector({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  final OdometerDirection direction;
  final ValueChanged<OdometerDirection> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: OdometerDirection.values
        .map(
          (value) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: value == OdometerDirection.reverse ? 0 : 8,
              ),
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: direction == value
                        ? (value == OdometerDirection.forward
                              ? Colors.green.shade700
                              : Colors.red.shade800)
                        : Colors.transparent,
                    side: BorderSide(
                      color: direction == value
                          ? Colors.transparent
                          : Colors.white38,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => onChanged(value),
                  child: FittedBox(
                    child: Text(switch (value) {
                      OdometerDirection.forward => 'FORWARD',
                      OdometerDirection.park => 'PARK',
                      OdometerDirection.reverse => 'REVERSE',
                    }, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

/// A visible Park or Reverse status chip. It is intentionally absent in Forward.
class OdometerDirectionIndicator extends StatelessWidget {
  const OdometerDirectionIndicator({super.key, required this.direction});

  final OdometerDirection direction;

  @override
  Widget build(BuildContext context) {
    if (direction == OdometerDirection.forward) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade800,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        direction == OdometerDirection.park ? 'PARK' : 'REVERSE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Standard Bump −/+ control, optionally guarded by a double-tap requirement.
class OdometerBumpButton extends StatelessWidget {
  const OdometerBumpButton({
    super.key,
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
