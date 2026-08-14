import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigator-only display snapshot. This provider intentionally has no
/// auto-dispose modifier so a dashboard replacement cannot release a hold.
class NavigatorHoldState {
  const NavigatorHoldState({
    this.isHeld = false,
    this.heldTotalDistance,
    this.heldTimestamp,
  });

  final bool isHeld;
  final double? heldTotalDistance;
  final String? heldTimestamp;
}

class NavigatorHoldNotifier extends Notifier<NavigatorHoldState> {
  @override
  NavigatorHoldState build() => const NavigatorHoldState();

  void hold({
    required double totalDistance,
    required DateTime timestamp,
  }) {
    state = NavigatorHoldState(
      isHeld: true,
      heldTotalDistance: totalDistance,
      heldTimestamp: timestamp.toIso8601String(),
    );
  }

  void release() => state = const NavigatorHoldState();
}

final navigatorHoldProvider =
    NotifierProvider<NavigatorHoldNotifier, NavigatorHoldState>(
  NavigatorHoldNotifier.new,
);
