import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key});

  Color _accuracyColor(double accuracy) {
    if (accuracy == 0) return Colors.grey;
    if (accuracy < 10) return Colors.green;
    if (accuracy <= 15) return Colors.yellow;
    return Colors.red;
  }

  String _cardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((bearing % 360) / 45).round() % directions.length];
  }

  Widget _telemetryTile({
    required String label,
    required String value,
    Color? valueColor,
    String? helper,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 34,
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                helper,
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isController =
        ref.watch(deviceRoleProvider) == DeviceRole.controller;
    final telemetry = isController
        ? ref.watch(liveTelemetryProvider)
        : ref.watch(bleTelemetryProvider).value;
    final settings = ref.watch(displaySettingsProvider);
    if (telemetry == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('LIVE DETAILS'),
          leading: const BackButton(),
        ),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final speed =
        settings.isMetric ? telemetry.speed * 3.6 : telemetry.speed * 2.23694;
    final speedUnit = settings.isMetric ? 'KPH' : 'MPH';
    final accuracyColor = _accuracyColor(telemetry.gpsAccuracy);
    final accuracy = telemetry.gpsAccuracy == 0
        ? 'NO FIX'
        : '± ${telemetry.gpsAccuracy.toStringAsFixed(1)}m';
    final bearing = telemetry.bearing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LIVE DETAILS'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 600 ? 12.0 : 16.0;
              final usableWidth = constraints.maxWidth - horizontalPadding * 2;
              final columnCount = usableWidth >= 680 ? 3 : 2;
              final tileWidth =
                  (usableWidth - (columnCount - 1) * 12) / columnCount;
              final tiles = [
                _telemetryTile(
                  label: 'LAT',
                  value: '${telemetry.latitude.toStringAsFixed(5)}°',
                ),
                _telemetryTile(
                  label: 'LON',
                  value: '${telemetry.longitude.toStringAsFixed(5)}°',
                ),
                _telemetryTile(
                  label: 'SPD',
                  value: '${speed.round()} $speedUnit',
                ),
                _telemetryTile(
                  label: 'HDG',
                  value: bearing == null
                      ? 'N/A'
                      : '${bearing.toStringAsFixed(0)}° ${_cardinalDirection(bearing)}',
                  helper: bearing == null
                      ? 'Data will be available when motion is detected'
                      : null,
                ),
                _telemetryTile(
                  label: 'GPS ACCURACY',
                  value: accuracy,
                  valueColor: accuracyColor,
                ),
              ];

              return Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: tileWidth, child: tile),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
