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
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _headingController.dispose();
    _distanceController.dispose();
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
              _numberField(
                _distanceController,
                'Distance (mi)',
                validator: (value) => _validateRange(value, 0, double.infinity),
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
        routeId: widget.routeId,
        deleted: widget.initialValue?.deleted,
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
