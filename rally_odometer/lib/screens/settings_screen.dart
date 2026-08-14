import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

import '../providers/rally_time_offset_provider.dart';
import '../providers/controller_display_view_provider.dart';
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

  bool get _isRemoteDisplay =>
      ref.read(deviceRoleProvider) != DeviceRole.controller;

  Future<void> _sendConfiguration(
    ControllerCommandOpcode opcode, {
    double? numericValue,
    String? stringValue,
  }) {
    return ref.read(bleTelemetryServiceProvider).sendCommand(
          ControllerCommand(
            opcode: opcode,
            numericValue: numericValue,
            stringValue: stringValue,
            timestamp: DateTime.now(),
          ),
        );
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

    if (_isRemoteDisplay) {
      await _sendConfiguration(
        ControllerCommandOpcode.setBumpAmount,
        numericValue: bumpAmount,
      );
    } else {
      ref.read(settingsProvider.notifier).setBumpAmount(bumpAmount);
    }
    setState(() {
      _bumpController.text = bumpAmount.toStringAsFixed(3);
    });
  }

  Future<void> _openRallyClockDialog() async {
    final timeDelta = ref.read(rallyTimeOffsetProvider);
    final currentRallyTime =
        ref.read(currentTimeProvider).value ?? DateTime.now().add(timeDelta);
    final controller = TextEditingController(
      text: formatRallyTime(currentRallyTime, false),
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('SYNC RALLY CLOCK'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Official rally time',
              hintText: 'HH:mm:ss',
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.clear,
              child: const Text('CLEAR'),
            ),
            TextButton(
              onPressed: () async {
                if (_isRemoteDisplay) {
                  await _sendConfiguration(
                    ControllerCommandOpcode.setRallyTimeOffset,
                    numericValue: 0,
                  );
                } else {
                  await ref.read(rallyTimeOffsetProvider.notifier).reset();
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('RESET TO DEVICE TIME'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final enteredTime = _parseClockTime(controller.text);
                if (enteredTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter time as HH:mm:ss')),
                  );
                  return;
                }

                final deviceTime = DateTime.now();
                final enteredRallyTime = DateTime(
                  deviceTime.year,
                  deviceTime.month,
                  deviceTime.day,
                  enteredTime.hour,
                  enteredTime.minute,
                  enteredTime.second,
                );
                var timeDelta = enteredRallyTime.difference(deviceTime);
                if (timeDelta > const Duration(hours: 12)) {
                  timeDelta -= const Duration(days: 1);
                } else if (timeDelta < const Duration(hours: -12)) {
                  timeDelta += const Duration(days: 1);
                }

                if (_isRemoteDisplay) {
                  await _sendConfiguration(
                    ControllerCommandOpcode.setRallyTimeOffset,
                    numericValue: timeDelta.inSeconds.toDouble(),
                  );
                } else {
                  await ref
                      .read(rallyTimeOffsetProvider.notifier)
                      .setOffset(timeDelta);
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('SYNC'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  DateTime? _parseClockTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3)!);
    if (hour > 23 || minute > 59 || second > 59) return null;
    return DateTime(2000, 1, 1, hour, minute, second);
  }

  Future<void> _calculateFactor() async {
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

    // The displayed odometer is already scaled by the current factor, so the
    // official-distance correction must scale that active factor in turn.
    final newFactor = calculateNewFactor(
      currentFactor: settings.calibrationFactor,
      measuredDistance: measured,
      currentAppDistance: currentAppDistance,
    );

    final confirmed = await _confirmCalculatedFactor(
      currentFactor: settings.calibrationFactor,
      newFactor: newFactor,
    );
    if (confirmed != true || !mounted) return;

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

  Future<bool?> _confirmCalculatedFactor({
    required double currentFactor,
    required double newFactor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: const Text(
          'CONFIRM CALIBRATION FACTOR',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURRENT FACTOR: ${currentFactor.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CALCULATED NEW FACTOR: ${newFactor.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.black,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONFIRM'),
          ),
        ],
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
    final role = ref.watch(deviceRoleProvider);
    final isController = role == DeviceRole.controller;
    final displayView = isController
        ? ref.watch(controllerDisplayViewProvider)
        : ref.watch(remoteDisplayViewProvider);
    final settings = ref.watch(displaySettingsProvider);
    final odometer = ref.watch(odometerProvider);
    final currentAppDistance = _currentAppDistance(settings, odometer);
    final factorText = settings.calibrationFactor.toStringAsFixed(5);
    final bumpText = settings.bumpAmount.toStringAsFixed(3);
    final currentRallyTime = ref.watch(currentTimeProvider).value ??
        DateTime.now().add(ref.watch(rallyTimeOffsetProvider));

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
                  onChanged: (_) {
                    if (_isRemoteDisplay) {
                      _sendConfiguration(
                        ControllerCommandOpcode.setMetric,
                        stringValue: (!settings.isMetric).toString(),
                      );
                    } else {
                      ref.read(settingsProvider.notifier).toggleMetric();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Decimal Minutes'),
                  subtitle: Text(
                    settings.isDecimalMinutes ? 'HH:mm.mm' : 'HH:mm:ss',
                  ),
                  value: settings.isDecimalMinutes,
                  onChanged: (_) {
                    if (_isRemoteDisplay) {
                      _sendConfiguration(
                        ControllerCommandOpcode.setDecimalMinutes,
                        stringValue: (!settings.isDecimalMinutes).toString(),
                      );
                    } else {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleDecimalMinutes();
                    }
                  },
                ),
                ListTile(
                  title: const Text('Sync Rally Clock'),
                  subtitle: Text(
                    'Official time: ${formatRallyTime(currentRallyTime, settings.isDecimalMinutes)}',
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: _openRallyClockDialog,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Device Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text('DISPLAY VIEW'),
                const SizedBox(height: 8),
                SegmentedButton<ControllerDisplayView>(
                  segments: const [
                    ButtonSegment(
                      value: ControllerDisplayView.driver,
                      label: Text('Driver View'),
                    ),
                    ButtonSegment(
                      value: ControllerDisplayView.navigator,
                      label: Text('Navigator View'),
                    ),
                  ],
                  selected: {displayView},
                  onSelectionChanged: (value) {
                    if (isController) {
                      ref
                          .read(controllerDisplayViewProvider.notifier)
                          .setView(value.first);
                    } else {
                      ref
                          .read(remoteDisplayViewProvider.notifier)
                          .setView(value.first);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  title: const Text('Device Role & Bluetooth'),
                  subtitle:
                      const Text('Controller, Driver, Navigator, and pairing'),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () => Navigator.pushNamed(context, '/role-selection'),
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
                  onChanged: (_) {
                    if (_isRemoteDisplay) {
                      _sendConfiguration(
                        ControllerCommandOpcode.setBumpRequireDoubleTap,
                        stringValue:
                            (!settings.bumpRequireDoubleTap).toString(),
                      );
                    } else {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleBumpRequireDoubleTap();
                    }
                  },
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
