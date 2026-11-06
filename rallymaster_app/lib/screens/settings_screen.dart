import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:rallymaster_ui/rallymaster_ui.dart';

/// Planning preferences that apply after a rally route has been selected.
class RallyMasterSettingsScreen extends ConsumerWidget {
  const RallyMasterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final distanceUnit = settings.isMetric ? 'km' : 'mi';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const RallySettingsSectionTitle('Calibration Factor'),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Calibration Factor'),
                  subtitle: const Text(
                    'Adjusts measured distance to match the route',
                  ),
                  trailing: Text(settings.calibrationFactor.toStringAsFixed(5)),
                  onTap: () => _editNumber(
                    context,
                    title: 'Calibration Factor',
                    value: settings.calibrationFactor,
                    decimalPlaces: 5,
                    min: 0.00001,
                    onSaved: notifier.setCalibrationFactor,
                  ),
                ),
                const RallySettingsSectionDivider(),
                const RallySettingsSectionTitle('Bump Increment'),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    'Bump Amount (${settings.isMetric ? 'KM' : 'MI'})',
                  ),
                  subtitle: Text(
                    '${settings.bumpAmount.toStringAsFixed(3)} $distanceUnit',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editNumber(
                    context,
                    title: 'Bump Amount ($distanceUnit)',
                    value: settings.bumpAmount,
                    decimalPlaces: 3,
                    min: 0.00001,
                    onSaved: notifier.setBumpAmount,
                  ),
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Require Double-Tap for Bumps'),
                  subtitle: Text(
                    settings.bumpRequireDoubleTap
                        ? 'Bump buttons trigger on double-tap'
                        : 'Bump buttons trigger on single-tap',
                  ),
                  value: settings.bumpRequireDoubleTap,
                  onChanged: notifier.setBumpRequireDoubleTap,
                ),
                const RallySettingsSectionDivider(),
                const RallySettingsSectionTitle('Display Settings'),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Use Metric (KM)'),
                  subtitle: Text(settings.isMetric ? 'Kilometers' : 'Miles'),
                  value: settings.isMetric,
                  onChanged: notifier.setMetric,
                ),
                const RallySettingsSectionDivider(),
                const RallySettingsSectionTitle('PrecisionDrive Assist'),
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  title: Text('Enabled during planning'),
                  subtitle: Text(
                    'Enhances distance continuity when GPS accuracy exceeds the engagement threshold',
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Engage when GPS accuracy exceeds (m)'),
                  subtitle: Text(
                    '${settings.sensorFusionAccuracyThresholdMeters.toStringAsFixed(0)} m',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editNumber(
                    context,
                    title: 'PrecisionDrive Engagement Accuracy (m)',
                    value: settings.sensorFusionAccuracyThresholdMeters,
                    decimalPlaces: 0,
                    min: 1,
                    max: 200,
                    onSaved: notifier.setSensorFusionAccuracyThresholdMeters,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required double value,
    required int decimalPlaces,
    required double min,
    double? max,
    required ValueChanged<double> onSaved,
  }) async {
    final controller = TextEditingController(
      text: value.toStringAsFixed(decimalPlaces),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Value'),
          onSubmitted: (_) =>
              _submitNumber(dialogContext, controller, min, max),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitNumber(dialogContext, controller, min, max),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onSaved(result);
  }

  void _submitNumber(
    BuildContext context,
    TextEditingController controller,
    double min,
    double? max,
  ) {
    final value = double.tryParse(controller.text);
    if (value == null ||
        !value.isFinite ||
        value < min ||
        (max != null && value > max)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a value from $min to ${max ?? 'above'}')),
      );
      return;
    }
    Navigator.of(context).pop(value);
  }
}
