import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import 'package:rallymaster_ui/rallymaster_ui.dart';

/// Keeps Park/Reverse audio active while the planning screen remains open.
/// It listens to odometer state, so closing the control dialog does not stop
/// the selected mode or its reminder.
class DirectionAlertScope extends ConsumerStatefulWidget {
  const DirectionAlertScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DirectionAlertScope> createState() =>
      _DirectionAlertScopeState();
}

class _DirectionAlertScopeState extends ConsumerState<DirectionAlertScope> {
  final _alerts = DirectionAlertService();
  OdometerDirection? _lastDirection;

  @override
  Widget build(BuildContext context) {
    final direction = ref.watch(
      odometerProvider.select((state) => state.direction),
    );
    if (_lastDirection != direction) {
      _lastDirection = direction;
      unawaited(_alerts.setDirection(direction));
    }
    return widget.child;
  }

  @override
  void dispose() {
    unawaited(_alerts.dispose());
    super.dispose();
  }
}
