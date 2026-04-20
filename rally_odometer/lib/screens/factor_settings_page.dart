import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/odometer_provider.dart';
import '../providers/settings_provider.dart';

class FactorSettingsPage extends ConsumerStatefulWidget {
  const FactorSettingsPage({super.key});

  @override
  ConsumerState<FactorSettingsPage> createState() => _FactorSettingsPageState();
}

class _FactorSettingsPageState extends ConsumerState<FactorSettingsPage> {
  late TextEditingController _factorController;
  final TextEditingController _measuredController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _factorController = TextEditingController(text: settings.calibrationFactor.toStringAsFixed(5));
  }

  void _calculateFactor() {
    double? measured = double.tryParse(_measuredController.text);
    final odometer = ref.read(odometerProvider);
    final settings = ref.read(settingsProvider);

    // Convert totalDistance (meters) to current units for comparison
    double currentAppDistance = settings.isMetric 
        ? odometer.totalDistance / 1000.0 
        : odometer.totalDistance / 1609.344;

    if (measured != null && currentAppDistance > 0) {
      // New Factor = Measured / (Raw GPS Distance)
      // Since currentAppDistance = (Raw GPS) * currentFactor / conversion
      // Raw GPS = currentAppDistance * conversion / currentFactor
      // New Factor = Measured / (currentAppDistance * conversion / currentFactor)
      // Actually, if we want Adjusted_Distance = Raw_GPS * NewFactor
      // And we want Adjusted_Distance to match Measured.
      // Measured = (Raw GPS) * NewFactor
      // Raw GPS = (Current Adjusted Distance) / Current Factor
      // New Factor = Measured / (Current Adjusted Distance / Current Factor)
      // New Factor = (Measured / Current Adjusted Distance) * Current Factor
      
      double newFactor = (measured / currentAppDistance) * settings.calibrationFactor;
      ref.read(settingsProvider.notifier).setCalibrationFactor(newFactor);
      setState(() {
        _factorController.text = newFactor.toStringAsFixed(5);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Factor updated to ${newFactor.toStringAsFixed(5)}")),
      );
    }
  }

  void _applyManualFactor() {
    double? factor = double.tryParse(_factorController.text);
    if (factor != null) {
      ref.read(settingsProvider.notifier).setCalibrationFactor(factor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Factor applied manually")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final odometer = ref.watch(odometerProvider);

    double currentAppDistance = settings.isMetric 
        ? odometer.totalDistance / 1000.0 
        : odometer.totalDistance / 1609.344;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
          children: [
            const Text("Display Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SwitchListTile(
              title: const Text("Use Metric (KM)"),
              subtitle: Text(settings.isMetric ? "Kilometers" : "Miles"),
              value: settings.isMetric,
              onChanged: (_) => ref.read(settingsProvider.notifier).toggleMetric(),
            ),
            SwitchListTile(
              title: const Text("Decimal Minutes"),
              subtitle: Text(settings.isDecimalMinutes ? "HH:mm.mm" : "HH:mm:ss"),
              value: settings.isDecimalMinutes,
              onChanged: (_) => ref.read(settingsProvider.notifier).toggleDecimalMinutes(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text("Calibration Factor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Method 1: Direct Entry"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _factorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Correction Factor"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _applyManualFactor,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Method 2: Calculate from Measured Mileage"),
            const SizedBox(height: 10),
            Text("Current App Distance: ${currentAppDistance.toStringAsFixed(3)} ${settings.isMetric ? 'KM' : 'MI'}"),
            TextField(
              controller: _measuredController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Official Measured Mileage (${settings.isMetric ? 'KM' : 'MI'})",
                hintText: "Enter distance from official rally sign",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _calculateFactor,
              child: const Text("Calculate & Apply Factor"),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
