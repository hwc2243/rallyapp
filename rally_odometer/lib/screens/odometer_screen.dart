import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/odometer_provider.dart';
import '../providers/settings_provider.dart';

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
    _refreshDisplay();
    // Update display every 50ms to support decimal minutes precision
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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
      double totalSeconds = time.hour * 3600.0 + 
                           time.minute * 60.0 + 
                           time.second + 
                           time.millisecond / 1000.0;
      double totalDecimalMinutes = totalSeconds / 60.0;
      
      int hours = (totalDecimalMinutes / 60.0).floor() % 24;
      double minutesWithFraction = totalDecimalMinutes % 60.0;
      
      String mmhh = minutesWithFraction.toStringAsFixed(2).padLeft(5, '0');
      
      if (mmhh == "60.00") {
        mmhh = "00.00";
        hours = (hours + 1) % 24;
      }
      
      String hh = hours.toString().padLeft(2, '0');
      return "$hh:$mmhh";
    } else {
      return DateFormat('HH:mm:ss').format(time);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double _convertDistance(double meters, bool isMetric) {
    if (isMetric) {
      return meters / 1000.0; // KM
    } else {
      return meters / 1609.344; // Miles
    }
  }

  Widget _buildSpeedIndicator(double speedMs, bool isMetric) {
    final double displaySpeed = isMetric ? speedMs * 3.6 : speedMs * 2.23694;
    final String unit = isMetric ? "KPH" : "MPH";
    final bool isActive = speedMs >= 0.8; // LocationService.minSpeedThreshold

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
              color: isActive ? const Color(0xFF00FF00) : Colors.grey[700],
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

    const totalColor = Color(0xFF00FF00); // High-viz Green
    const intervalColor = Color(0xFFFFFF00); // High-viz Yellow

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
                      label: "TOTAL (${settings.isMetric ? 'KM' : 'MI'})",
                      value: _convertDistance(totalDisplayDistance, settings.isMetric),
                      time: totalDisplayTime,
                      color: totalColor,
                      isDimmed: odometer.isHeld,
                    ),
                  ),
                  _buildSpeedIndicator(odometer.currentSpeed, settings.isMetric),
                  // Bottom Row: Interval Mileage
                  Expanded(
                    child: _buildOdometerDisplay(
                      label: "INTERVAL (${settings.isMetric ? 'KM' : 'MI'})",
                      value: _convertDistance(odometer.intervalDistance, settings.isMetric),
                      time: _currentTimeDisplay,
                      color: intervalColor,
                    ),
                  ),
                ],
              ),
            ),
            // Control Column (Right side, 15% width)
            Container(
              width: MediaQuery.of(context).size.width * 0.15,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.black, // Pure black background
                border: Border(left: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: Column(
                children: [
                  // Top Row Controls
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
                  // Bottom Row Controls
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
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.grey[900],
        child: const Icon(Icons.settings, color: Colors.white70),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    );
  }

  Widget _buildOdometerDisplay({
    required String label,
    required double value,
    required String time,
    required Color color,
    bool isDimmed = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 16)),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontFamily: 'Courier',
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
                      fontSize: 120, // Max size, will scale down to fit
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth * 0.9;
        final double clampedSize = size.clamp(60.0, 88.0);
        
        return SizedBox(
          width: clampedSize,
          height: clampedSize,
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }
}
