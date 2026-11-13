import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/route_instruction_dto.dart';

/// Edits a route instruction captured at the current planning position.
class RouteInstructionDetailsDialog extends StatefulWidget {
  const RouteInstructionDetailsDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.distance,
    required this.position,
    required this.instructionNumber,
    required this.organizationId,
    required this.routeId,
    required this.allowedInstructionTypes,
    this.suggestedSpeed,
    this.rallyDefaultSpeed,
    this.defaultPauseDurationMillis,
    this.suggestedTransitDurationMillis,
    this.initialValue,
  });

  final double latitude;
  final double longitude;
  final int heading;
  final double distance;
  final int position;
  final int instructionNumber;
  final int organizationId;
  final int? routeId;
  final List<String> allowedInstructionTypes;
  final double? suggestedSpeed;
  final double? rallyDefaultSpeed;
  final int? defaultPauseDurationMillis;
  final int? suggestedTransitDurationMillis;
  final RouteInstructionDto? initialValue;

  @override
  State<RouteInstructionDetailsDialog> createState() =>
      _RouteInstructionDetailsDialogState();
}

class _RouteInstructionDetailsDialogState
    extends State<RouteInstructionDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _headingController;
  late final TextEditingController _distanceController;
  late final TextEditingController _speedController;
  late final TextEditingController _pauseController;
  late final TextEditingController _transitDurationController;
  late String _instructionType;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _instructionsController = TextEditingController(
      text: initial?.instructionText ?? '',
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _latitudeController = TextEditingController(
      text: (initial?.latitude ?? widget.latitude).toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: (initial?.longitude ?? widget.longitude).toStringAsFixed(6),
    );
    _headingController = TextEditingController(
      text: '${initial?.heading ?? widget.heading}',
    );
    _distanceController = TextEditingController(
      text: (initial?.distance ?? widget.distance).toStringAsFixed(3),
    );
    _instructionType =
        initial?.instructionType ?? widget.allowedInstructionTypes.first;
    _speedController = TextEditingController(
      text: (initial?.speed ?? widget.suggestedSpeed)?.toString() ?? '',
    );
    _pauseController = TextEditingController(
      text: _formatDuration(initial?.pauseDurationMillis),
    );
    _transitDurationController = TextEditingController(
      text: _formatDuration(
        initial?.transitDurationMillis ?? widget.suggestedTransitDurationMillis,
      ),
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _headingController.dispose();
    _distanceController.dispose();
    _speedController.dispose();
    _pauseController.dispose();
    _transitDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      _isEditing ? 'Edit route instruction' : 'Route instruction details',
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(_instructionsController, 'Instructions', maxLines: 3),
              _textField(_notesController, 'Notes', maxLines: 3),
              DropdownButtonFormField<String>(
                initialValue: _instructionType,
                decoration: const InputDecoration(labelText: 'NRI type'),
                items: widget.allowedInstructionTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_formatType(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _instructionType = value!),
              ),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _speedController,
                      'Speed for next leg',
                      validator: _validateOptionalNonNegative,
                    ),
                  ),
                  if (widget.rallyDefaultSpeed != null)
                    TextButton(
                      onPressed: () => setState(
                        () => _speedController.text = widget.rallyDefaultSpeed
                            .toString(),
                      ),
                      child: const Text('Rally Speed'),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      _pauseController,
                      'Pause (mm:ss)',
                      validator: _validateDuration,
                    ),
                  ),
                  if (widget.defaultPauseDurationMillis != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip: 'Subtract default pause',
                          onPressed: () => _adjustPause(-1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Add default pause',
                          onPressed: () => _adjustPause(1),
                        ),
                      ],
                    ),
                ],
              ),
              if (_instructionType == 'END_TRANSIT')
                _textField(
                  _transitDurationController,
                  'Transit duration (mm:ss)',
                  validator: _validateRequiredDuration,
                ),
              _numberField(
                _distanceController,
                'Mileage (mi)',
                validator: (value) => _validateRange(value, 0, double.infinity),
              ),
              _numberField(
                _latitudeController,
                'Latitude',
                validator: (value) => _validateRange(value, -90, 90),
              ),
              _numberField(
                _longitudeController,
                'Longitude',
                validator: (value) => _validateRange(value, -180, 180),
              ),
              _numberField(
                _headingController,
                'Heading (degrees)',
                decimal: false,
                validator: (value) => _validateRange(value, 0, 359),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _save,
        child: Text(_isEditing ? 'Save instruction' : 'Add instruction'),
      ),
    ],
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    maxLines: maxLines,
    validator: validator,
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool decimal = true,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(
      decimal: decimal,
      signed: true,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(decimal ? r'[-0-9.]' : r'[0-9]'),
      ),
    ],
    validator: validator,
  );

  String? _validateRange(String? value, double min, double max) {
    final number = double.tryParse(value ?? '');
    if (number == null || !number.isFinite || number < min || number > max) {
      return 'Enter a value from $min to $max';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      RouteInstructionDto(
        id: widget.initialValue?.id,
        serverId: widget.initialValue?.serverId,
        itemType: 'NRI',
        position: widget.position,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        heading: int.parse(_headingController.text) % 360,
        distance: double.parse(_distanceController.text),
        notes: _nullable(_notesController.text),
        organizationId: widget.organizationId,
        instructionNumber: widget.instructionNumber,
        instructionText: _nullable(_instructionsController.text),
        instructionType: _instructionType,
        speed: _optionalDouble(_speedController.text),
        pauseDurationMillis: _parseDuration(_pauseController.text),
        transitDurationMillis: _instructionType == 'END_TRANSIT'
            ? _parseDuration(_transitDurationController.text)
            : null,
        routeId: widget.routeId,
        deleted: widget.initialValue?.deleted,
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _optionalDouble(String value) =>
      value.trim().isEmpty ? null : double.tryParse(value.trim());

  int? _parseDuration(String value) {
    if (value.trim().isEmpty) return null;
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null ||
        seconds == null ||
        minutes < 0 ||
        seconds < 0 ||
        seconds >= 60)
      return null;
    return Duration(minutes: minutes, seconds: seconds).inMilliseconds;
  }

  String _formatDuration(int? value) {
    if (value == null) return '';
    final seconds = value ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String? _validateDuration(String? value) =>
      value == null || value.trim().isEmpty || _parseDuration(value) != null
      ? null
      : 'Use mm:ss';
  String? _validateRequiredDuration(String? value) =>
      _parseDuration(value ?? '') == null ? 'Enter mm:ss' : null;
  String? _validateOptionalNonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value);
    return number == null || number < 0 ? 'Enter a non-negative speed' : null;
  }

  void _adjustPause(int multiplier) {
    final current = _parseDuration(_pauseController.text) ?? 0;
    final adjusted = (current + multiplier * widget.defaultPauseDurationMillis!)
        .clamp(0, 1 << 62)
        .toInt();
    setState(() => _pauseController.text = _formatDuration(adjusted));
  }

  static String _formatType(String value) => value
      .toLowerCase()
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
