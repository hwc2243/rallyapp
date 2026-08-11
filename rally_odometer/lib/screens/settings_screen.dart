import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/odometer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mileage_entry_dialog.dart';

enum CalibrationEntryMode { direct, measured }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _factorController;
  late final TextEditingController _measuredController;
  late final TextEditingController _bumpController;
  CalibrationEntryMode _entryMode = CalibrationEntryMode.direct;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _factorController = TextEditingController(
      text: settings.calibrationFactor.toStringAsFixed(5),
    );
    _measuredController = TextEditingController();
    _bumpController = TextEditingController(
      text: settings.bumpAmount.toStringAsFixed(3),
    );
  }

  @override
  void dispose() {
    _factorController.dispose();
    _measuredController.dispose();
    _bumpController.dispose();
    super.dispose();
  }

  double _currentAppDistance(
    OdometerSettings settings,
    OdometerState odometer,
  ) {
    return settings.isMetric
        ? odometer.totalDistance / 1000.0
        : odometer.totalDistance / 1609.344;
  }

  void _setEntryMode(CalibrationEntryMode mode) {
    setState(() {
      _entryMode = mode;
    });
  }

  Future<void> _openDirectFactorDialog() async {
    final factor = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MileageEntryDialog(
        initialValue: _factorController.text,
        title: 'DIRECT ENTRY FACTOR',
        decimalPlaces: 5,
        maxDigitsBeforeDecimal: 2,
      ),
    );

    if (factor == null) return;

    ref.read(settingsProvider.notifier).setCalibrationFactor(factor);
    setState(() {
      _entryMode = CalibrationEntryMode.direct;
      _factorController.text = factor.toStringAsFixed(5);
    });
  }

  Future<void> _openMeasuredMileageDialog() async {
    final settings = ref.read(settingsProvider);
    final measured = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MileageEntryDialog(
        initialValue: _measuredController.text.isEmpty
            ? '0.000'
            : _measuredController.text,
        title: 'MEASURED MILEAGE (${settings.isMetric ? 'km' : 'mi'})',
        decimalPlaces: 3,
        maxDigitsBeforeDecimal: 8,
      ),
    );

    if (measured == null) return;

    setState(() {
      _entryMode = CalibrationEntryMode.measured;
      _measuredController.text = measured.toStringAsFixed(3);
    });
  }

  Future<void> _openBumpAmountDialog() async {
    final settings = ref.read(settingsProvider);
    final bumpAmount = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MileageEntryDialog(
        initialValue: _bumpController.text,
        title: 'BUMP AMOUNT (${settings.isMetric ? 'km' : 'mi'})',
        decimalPlaces: 3,
        maxDigitsBeforeDecimal: 2,
      ),
    );

    if (bumpAmount == null) return;

    ref.read(settingsProvider.notifier).setBumpAmount(bumpAmount);
    setState(() {
      _bumpController.text = bumpAmount.toStringAsFixed(3);
    });
  }

  void _calculateFactor() {
    final measured = double.tryParse(_measuredController.text);
    final odometer = ref.read(odometerProvider);
    final settings = ref.read(settingsProvider);
    final currentAppDistance = _currentAppDistance(settings, odometer);

    if (measured == null || measured <= 0 || currentAppDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a measured mileage and ensure current mileage is above 0',
          ),
        ),
      );
      return;
    }

    final newFactor =
        (measured / currentAppDistance) * settings.calibrationFactor;
    ref.read(settingsProvider.notifier).setCalibrationFactor(newFactor);
    setState(() {
      _entryMode = CalibrationEntryMode.measured;
      _factorController.text = newFactor.toStringAsFixed(5);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Factor updated to ${newFactor.toStringAsFixed(5)}'),
      ),
    );
  }

  Widget _buildModeToggle(CalibrationEntryMode mode) {
    final isSelected = _entryMode == mode;
    return IconButton(
      onPressed: () => _setEntryMode(mode),
      icon: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      color: isSelected ? Theme.of(context).colorScheme.primary : null,
      tooltip: mode == CalibrationEntryMode.direct
          ? 'Use direct entry'
          : 'Use measured mileage',
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            enableInteractiveSelection: false,
            onTap: onTap,
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.dialpad),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final odometer = ref.watch(odometerProvider);
    final currentAppDistance = _currentAppDistance(settings, odometer);
    final factorText = settings.calibrationFactor.toStringAsFixed(5);
    final bumpText = settings.bumpAmount.toStringAsFixed(3);

    if (_factorController.text != factorText) {
      _factorController.text = factorText;
    }
    if (_bumpController.text != bumpText) {
      _bumpController.text = bumpText;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Display Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SwitchListTile(
                  title: const Text('Use Metric (KM)'),
                  subtitle: Text(settings.isMetric ? 'Kilometers' : 'Miles'),
                  value: settings.isMetric,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleMetric(),
                ),
                SwitchListTile(
                  title: const Text('Decimal Minutes'),
                  subtitle: Text(
                    settings.isDecimalMinutes ? 'HH:mm.mm' : 'HH:mm:ss',
                  ),
                  value: settings.isDecimalMinutes,
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .toggleDecimalMinutes(),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Bump Increment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                _buildDialogField(
                  controller: _bumpController,
                  label: 'Bump Amount (${settings.isMetric ? 'KM' : 'MI'})',
                  onTap: _openBumpAmountDialog,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require Double-Tap for Bumps'),
                  subtitle: Text(
                    settings.bumpRequireDoubleTap
                        ? 'Bump buttons trigger on double-tap'
                        : 'Bump buttons trigger on single-tap',
                  ),
                  value: settings.bumpRequireDoubleTap,
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .toggleBumpRequireDoubleTap(),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Calibration Factor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current app mileage: ${currentAppDistance.toStringAsFixed(3)} ${settings.isMetric ? 'KM' : 'MI'}',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildModeToggle(CalibrationEntryMode.direct),
                    const SizedBox(width: 8),
                    const SizedBox(width: 150, child: Text('Direct Entry')),
                    Expanded(
                      child: _buildDialogField(
                        controller: _factorController,
                        label: 'Calibration Factor',
                        onTap: _openDirectFactorDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildModeToggle(CalibrationEntryMode.measured),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 150,
                      child: Text('Measure Mileage Entry'),
                    ),
                    Expanded(
                      child: _buildDialogField(
                        controller: _measuredController,
                        label:
                            'Measured Mileage (${settings.isMetric ? 'KM' : 'MI'})',
                        onTap: _openMeasuredMileageDialog,
                        trailing: ElevatedButton(
                          onPressed: _entryMode == CalibrationEntryMode.measured
                              ? _calculateFactor
                              : null,
                          child: const Text('Calculate'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
