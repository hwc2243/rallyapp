import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller-authoritative display hold shared by every Navigator client.
class NavigatorDisplayHoldState {
  const NavigatorDisplayHoldState({
    this.isHeld = false,
    this.heldTotalDistance,
    this.heldTimestamp,
  });

  final bool isHeld;
  final double? heldTotalDistance;
  final DateTime? heldTimestamp;
}

class NavigatorDisplayHoldNotifier extends Notifier<NavigatorDisplayHoldState> {
  @override
  NavigatorDisplayHoldState build() => const NavigatorDisplayHoldState();

  void hold({required double totalDistance, required DateTime timestamp}) {
    state = NavigatorDisplayHoldState(
      isHeld: true,
      heldTotalDistance: totalDistance,
      heldTimestamp: timestamp,
    );
  }

  void release() => state = const NavigatorDisplayHoldState();
}

final navigatorDisplayHoldProvider =
    NotifierProvider<NavigatorDisplayHoldNotifier, NavigatorDisplayHoldState>(
  NavigatorDisplayHoldNotifier.new,
);
