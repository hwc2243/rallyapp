import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/checkpoint_dto.dart';

/// Edits the checkpoint information captured at a precisely located position.
class CheckpointDetailsDialog extends StatefulWidget {
  const CheckpointDetailsDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.distance,
    required this.position,
    required this.checkpointNumber,
    required this.organizationId,
    required this.routeId,
    this.initialValue,
  });

  final double latitude;
  final double longitude;
  final int heading;
  final double distance;
  final int position;
  final int checkpointNumber;
  final int organizationId;
  final int? routeId;
  final CheckpointDto? initialValue;

  @override
  State<CheckpointDetailsDialog> createState() =>
      _CheckpointDetailsDialogState();
}

class _CheckpointDetailsDialogState extends State<CheckpointDetailsDialog> {
  static const _checkpointTypes = [
    'PASSAGE_CONTROL',
    'TIMED_CONTROL',
    'TIME_CHECK',
    'RESTART',
    'START',
    'FINISH',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _headingController;
  late final TextEditingController _distanceController;
  late String _checkpointType;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _nameController = TextEditingController(text: initial?.name ?? '');
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
    _checkpointType = initial?.checkpointType ?? _checkpointTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _headingController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_isEditing ? 'Edit checkpoint' : 'Checkpoint details'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _checkpointType,
                decoration: const InputDecoration(labelText: 'Checkpoint type'),
                items: _checkpointTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_formatCheckpointType(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _checkpointType = value!),
              ),
              _textField(_nameController, 'Name'),
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
        child: Text(_isEditing ? 'Save checkpoint' : 'Add checkpoint'),
      ),
    ],
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    maxLines: maxLines,
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
      CheckpointDto(
        id: widget.initialValue?.id,
        serverId: widget.initialValue?.serverId,
        itemType: 'CHECKPOINT',
        position: widget.position,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        heading: int.parse(_headingController.text) % 360,
        distance: double.parse(_distanceController.text),
        notes: _nullable(_notesController.text),
        organizationId: widget.organizationId,
        checkpointNumber: widget.checkpointNumber,
        checkpointType: _checkpointType,
        name: _nullable(_nameController.text),
        routeId: widget.routeId,
        deleted: widget.initialValue?.deleted,
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatCheckpointType(String type) => type
      .split('_')
      .map((word) => '${word[0]}${word.substring(1).toLowerCase()}')
      .join(' ');
}
