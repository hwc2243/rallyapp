import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/mileage_entry_dialog.dart';

class OdometerScreen extends ConsumerStatefulWidget {
  const OdometerScreen({super.key});

  @override
  ConsumerState<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends ConsumerState<OdometerScreen> {
  static const double _bumpControlColumnWidth = 92;

  String _currentTimeDisplay = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _refreshDisplay();
    // Global refresh timer set to 100ms as per specifications
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _refreshDisplay();
    });
  }

  void _refreshDisplay() {
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    setState(() {
      _currentTimeDisplay = _formatTime(
        DateTime.now(),
        settings.isDecimalMinutes,
      );
    });
  }

  String _formatTime(DateTime time, bool isDecimalMinutes) {
    if (isDecimalMinutes) {
      // HH:mm.[hundredths]
      // Formula for Hundredths: (Seconds / 60) * 100 or simply (Seconds * 5) / 3
      double totalSecondsInMinute = time.second + time.millisecond / 1000.0;
      double hundredths = (totalSecondsInMinute / 60.0) * 100.0;

      String hh = time.hour.toString().padLeft(2, '0');
      String mm = time.minute.toString().padLeft(2, '0');
      String ss = hundredths.toInt().toString().padLeft(2, '0');

      return "$hh:$mm.$ss";
    } else {
      return DateFormat('HH:mm:ss').format(time);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  double _convertDistance(double meters, bool isMetric) {
    if (isMetric) {
      return meters / 1000.0; // KM
    } else {
      return meters / 1609.344; // Miles
    }
  }

  Widget _buildGpsIndicator(double accuracy) {
    Color iconColor;
    if (accuracy == 0) {
      iconColor = Colors.grey;
    } else if (accuracy < 10) {
      iconColor = Colors.green;
    } else if (accuracy <= 15) {
      iconColor = Colors.yellow;
    } else {
      iconColor = Colors.red;
    }

    return Icon(Icons.satellite_alt, color: iconColor, size: 24);
  }

  Widget _buildSpeedIndicator(
    double speedMs,
    bool isMetric,
    bool isStationary,
  ) {
    final double displaySpeed = isMetric ? speedMs * 3.6 : speedMs * 2.23694;
    final String unit = isMetric ? "KPH" : "MPH";

    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "SPEED: ${displaySpeed.toStringAsFixed(1)} $unit",
            style: TextStyle(
              color: isStationary ? Colors.grey[700] : const Color(0xFF00FF00),
              fontSize: 24,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final odometer = ref.watch(odometerProvider);
    final telemetry = ref.watch(liveTelemetryProvider);
    final settings = ref.watch(settingsProvider);

    final totalDisplayDistance = odometer.isHeld
        ? (odometer.frozenTotalDistance ?? odometer.totalDistance)
        : odometer.totalDistance;

    final totalDisplayTime = odometer.isHeld && odometer.frozenTime != null
        ? _formatTime(odometer.frozenTime!, settings.isDecimalMinutes)
        : _currentTimeDisplay;

    final isReverse = odometer.direction == OdometerDirection.reverse;
    final isParked = odometer.direction == OdometerDirection.park;

    final totalColor = isReverse ? Colors.red : const Color(0xFF00FF00);
    final intervalColor = isReverse ? Colors.red : const Color(0xFFFFFF00);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Main Display Area
                Expanded(
                  child: Column(
                    children: [
                      // Top Row: Total Mileage
                      Expanded(
                        child: _buildOdometerDisplay(
                          label: "TOTAL",
                          unit: settings.isMetric ? "km" : "mi",
                          value: _convertDistance(
                            totalDisplayDistance,
                            settings.isMetric,
                          ),
                          time: totalDisplayTime,
                          color: totalColor,
                          isDimmed: odometer.isHeld || isParked,
                          accuracy: telemetry.gpsAccuracy,
                          showGps: true,
                          trailingControlWidth: _bumpControlColumnWidth,
                          trailingControls: _buildBumpControls(),
                        ),
                      ),
                      _buildSpeedIndicator(
                        telemetry.speed,
                        settings.isMetric,
                        odometer.isStationaryLock,
                      ),
                      // Bottom Row: Interval Mileage
                      Expanded(
                        child: _buildOdometerDisplay(
                          label: "INTERVAL",
                          unit: settings.isMetric ? "km" : "mi",
                          value: _convertDistance(
                            odometer.intervalDistance,
                            settings.isMetric,
                          ),
                          time: _currentTimeDisplay,
                          color: intervalColor,
                          isDimmed: isParked,
                          trailingControlWidth: _bumpControlColumnWidth,
                        ),
                      ),
                    ],
                  ),
                ),
                // Control Column (Right side)
                Container(
                  width: MediaQuery.of(context).size.width * 0.20,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    border: Border(
                      left: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Direction Segmented Control (FPR)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDirectionButton(
                                label: "FORWARD",
                                isActive:
                                    odometer.direction ==
                                    OdometerDirection.forward,
                                activeColor: Colors.green,
                                onPressed: () => ref
                                    .read(odometerProvider.notifier)
                                    .setDirection(OdometerDirection.forward),
                              ),
                              _buildDirectionButton(
                                label: "PARK",
                                isActive:
                                    odometer.direction ==
                                    OdometerDirection.park,
                                activeColor: Colors.white,
                                onPressed: () => ref
                                    .read(odometerProvider.notifier)
                                    .setDirection(OdometerDirection.park),
                              ),
                              _buildDirectionButton(
                                label: "REVERSE",
                                isActive:
                                    odometer.direction ==
                                    OdometerDirection.reverse,
                                activeColor: Colors.red,
                                onPressed: () => ref
                                    .read(odometerProvider.notifier)
                                    .setDirection(OdometerDirection.reverse),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VerticalDivider(color: Colors.white24, width: 1),
                      // Action Buttons
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildControlButton(
                                    label: odometer.isHeld ? "RELEASE" : "HOLD",
                                    color: odometer.isHeld
                                        ? Colors.red
                                        : Colors.green,
                                    onPressed: () => ref
                                        .read(odometerProvider.notifier)
                                        .toggleHold(),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildControlButton(
                                    label: "RESET",
                                    color: Colors.grey[800]!,
                                    onPressed: () => ref
                                        .read(odometerProvider.notifier)
                                        .resetTotal(),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: _buildControlButton(
                                        label: "RESET",
                                        color: Colors.grey[800]!,
                                        onPressed: () => ref
                                            .read(odometerProvider.notifier)
                                            .resetInterval(),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: _buildMenu(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: odometer.isCalibrating ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Calibrating...',
                        style: TextStyle(
                          color: Colors.amber,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Menu',
      color: Colors.grey[900],
      icon: const Icon(Icons.menu, color: Colors.white70),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.settings:
            Navigator.pushNamed(context, '/settings');
          case _MenuAction.details:
            Navigator.pushNamed(context, '/details');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _MenuAction.settings, child: Text('Settings')),
        PopupMenuItem(value: _MenuAction.details, child: Text('Details')),
      ],
    );
  }

  void _showMileageEntryDialog(bool isTotal) async {
    final odometer = ref.read(odometerProvider);
    final settings = ref.read(settingsProvider);

    double currentValue = isTotal
        ? _convertDistance(odometer.totalDistance, settings.isMetric)
        : _convertDistance(odometer.intervalDistance, settings.isMetric);

    final double? newValue = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MileageEntryDialog(
        initialValue: currentValue.toStringAsFixed(3),
        title:
            "SET ${isTotal ? "TOTAL" : "INTERVAL"} (${settings.isMetric ? "km" : "mi"})",
      ),
    );

    if (newValue != null) {
      // Convert back to meters
      double meters = settings.isMetric
          ? newValue * 1000.0
          : newValue * 1609.344;

      if (isTotal) {
        ref.read(odometerProvider.notifier).setTotalDistance(meters);
      } else {
        ref.read(odometerProvider.notifier).setIntervalDistance(meters);
      }
    }
  }

  Widget _buildDirectionButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required Color activeColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isActive ? activeColor : Colors.transparent,
              side: BorderSide(color: isActive ? activeColor : Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2),
            ),
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? (activeColor == Colors.white
                            ? Colors.black
                            : Colors.white)
                      : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOdometerDisplay({
    required String label,
    required String unit,
    required double value,
    required String time,
    required Color color,
    bool isDimmed = false,
    double accuracy = 0,
    bool showGps = false,
    double trailingControlWidth = 0,
    Widget? trailingControls,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "$label ($unit)",
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showGps)
                Align(
                  alignment: Alignment.center,
                  child: _buildGpsIndicator(accuracy),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Opacity(
              opacity: isDimmed ? 0.7 : 1.0,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _showMileageEntryDialog(label == "TOTAL"),
                        behavior: HitTestBehavior.opaque,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            value.toStringAsFixed(3),
                            style: TextStyle(
                              color: color,
                              fontSize: 140,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: trailingControlWidth,
                    child: trailingControls ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBumpControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBumpButton(label: 'BUMP+', isPositive: true),
        const SizedBox(height: 8),
        _buildBumpButton(label: 'BUMP-', isPositive: false),
      ],
    );
  }

  Widget _buildBumpButton({required String label, required bool isPositive}) {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(odometerProvider.notifier);
    void callback() => notifier.applyBump(isPositive);
    final bumpUnit = settings.isMetric ? 'KM' : 'MI';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: settings.bumpRequireDoubleTap ? null : callback,
      onDoubleTap: settings.bumpRequireDoubleTap ? callback : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 84,
            height: 48,
            child: AbsorbPointer(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                onPressed: () {},
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${settings.bumpAmount.toStringAsFixed(3)} $bumpUnit',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (settings.bumpRequireDoubleTap)
            Positioned(
              top: -8,
              right: -16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'x2',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { settings, details }
