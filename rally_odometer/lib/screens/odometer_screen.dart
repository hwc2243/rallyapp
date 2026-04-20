import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/odometer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/location_service.dart';

class OdometerScreen extends ConsumerStatefulWidget {
  const OdometerScreen({super.key});

  @override
  ConsumerState<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends ConsumerState<OdometerScreen> {
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
      _currentTimeDisplay = _formatTime(DateTime.now(), settings.isDecimalMinutes);
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

  Widget _buildSpeedIndicator(double speedMs, bool isMetric, bool isStationary) {
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
            "SPD: ${displaySpeed.toStringAsFixed(1)} $unit",
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
        child: Row(
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
                      value: _convertDistance(totalDisplayDistance, settings.isMetric),
                      time: totalDisplayTime,
                      color: totalColor,
                      isDimmed: odometer.isHeld || isParked,
                      accuracy: odometer.lastAccuracy,
                      showGps: true,
                    ),
                  ),
                  _buildSpeedIndicator(odometer.currentSpeed, settings.isMetric, odometer.isStationaryLock),
                  // Bottom Row: Interval Mileage
                  Expanded(
                    child: _buildOdometerDisplay(
                      label: "INTERVAL",
                      unit: settings.isMetric ? "km" : "mi",
                      value: _convertDistance(odometer.intervalDistance, settings.isMetric),
                      time: _currentTimeDisplay,
                      color: intervalColor,
                      isDimmed: isParked,
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
                border: Border(left: BorderSide(color: Colors.white24, width: 1)),
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
                            isActive: odometer.direction == OdometerDirection.forward,
                            activeColor: Colors.green,
                            onPressed: () => ref.read(odometerProvider.notifier).setDirection(OdometerDirection.forward),
                          ),
                          _buildDirectionButton(
                            label: "PARK",
                            isActive: odometer.direction == OdometerDirection.park,
                            activeColor: Colors.white,
                            onPressed: () => ref.read(odometerProvider.notifier).setDirection(OdometerDirection.park),
                          ),
                          _buildDirectionButton(
                            label: "REVERSE",
                            isActive: odometer.direction == OdometerDirection.reverse,
                            activeColor: Colors.red,
                            onPressed: () => ref.read(odometerProvider.notifier).setDirection(OdometerDirection.reverse),
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
                                color: odometer.isHeld ? Colors.red : Colors.green,
                                onPressed: () => ref.read(odometerProvider.notifier).toggleHold(),
                              ),
                              const SizedBox(height: 16),
                              _buildControlButton(
                                label: "RESET",
                                color: Colors.grey[800]!,
                                onPressed: () => ref.read(odometerProvider.notifier).resetTotal(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        Expanded(
                          child: Center(
                            child: _buildControlButton(
                              label: "RESET",
                              color: Colors.grey[800]!,
                              onPressed: () => ref.read(odometerProvider.notifier).resetInterval(),
                            ),
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
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.grey[900],
        child: const Icon(Icons.settings, color: Colors.white70),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 2),
            ),
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? (activeColor == Colors.white ? Colors.black : Colors.white) : Colors.grey,
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
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              if (showGps)
                Align(
                  alignment: Alignment.center,
                  child: _buildGpsIndicator(accuracy),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Opacity(
              opacity: isDimmed ? 0.7 : 1.0,
              child: Center(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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

