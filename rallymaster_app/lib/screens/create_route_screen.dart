import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/route_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({
    super.key,
    required this.session,
    required this.rally,
    required this.accessToken,
    this.initialRoute,
  });

  final AppSession session;
  final RallyDto rally;
  final Future<String> Function() accessToken;
  final RouteDto? initialRoute;

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeZoneController = TextEditingController(text: 'America/New_York');
  final _maximumScoreController = TextEditingController(text: '100');
  final _defaultSpeedController = TextEditingController();
  final _restartIntervalController = TextEditingController();
  final _defaultPauseController = TextEditingController();
  DateTime _carZeroStart = DateTime.now().add(const Duration(minutes: 5));
  var _saving = false;
  String? _error;

  bool get _editing => widget.initialRoute != null;

  @override
  void initState() {
    super.initState();
    final route = widget.initialRoute;
    if (route == null) return;
    _nameController.text = route.name ?? '';
    _descriptionController.text = route.description ?? '';
    _timeZoneController.text = route.timeZone ?? 'America/New_York';
    _maximumScoreController.text = '${route.maximumCheckpointScore ?? 100}';
    _defaultSpeedController.text = route.defaultSpeed?.toString() ?? '';
    _restartIntervalController.text = _formatDuration(
      route.restartIntervalMillis,
    );
    _defaultPauseController.text = _formatDuration(
      route.defaultPauseDurationMillis,
    );
    if (route.carZeroStartEpochMillis != null) {
      _carZeroStart = DateTime.fromMillisecondsSinceEpoch(
        route.carZeroStartEpochMillis!,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeZoneController.dispose();
    _maximumScoreController.dispose();
    _defaultSpeedController.dispose();
    _restartIntervalController.dispose();
    _defaultPauseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rallyId = widget.rally.serverId;
    if (rallyId == null) {
      setState(() => _error = 'The selected rally has no server id.');
      return;
    }
    final maximumScore = int.tryParse(_maximumScoreController.text.trim());
    final defaultSpeed = _optionalDouble(_defaultSpeedController.text);
    final restartInterval = _parseDuration(_restartIntervalController.text);
    final defaultPause = _parseDuration(_defaultPauseController.text);
    if (maximumScore == null || maximumScore < 0) {
      setState(() => _error = 'Enter a valid maximum checkpoint score.');
      return;
    }
    if ((_defaultSpeedController.text.trim().isNotEmpty &&
            defaultSpeed == null) ||
        (_restartIntervalController.text.trim().isNotEmpty &&
            restartInterval == null) ||
        (_defaultPauseController.text.trim().isNotEmpty &&
            defaultPause == null)) {
      setState(
        () =>
            _error = 'Use non-negative numbers and durations in mm:ss format.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RouteProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RouteProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final value = RouteDto(
        serverId: widget.initialRoute?.serverId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        rallyId: rallyId,
        status: 'PLAN',
        timeZone: _timeZoneController.text.trim(),
        carZeroStartEpochMillis: _carZeroStart.millisecondsSinceEpoch,
        maximumCheckpointScore: maximumScore,
        defaultSpeed: defaultSpeed,
        restartIntervalMillis: restartInterval,
        defaultPauseDurationMillis: defaultPause,
      ).forOrganizationId(widget.session.organizationId);
      final route = _editing
          ? await provider.update(widget.initialRoute!.serverId!, value)
          : await provider.create(value);
      if (mounted) Navigator.of(context).pop(route);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to ${_editing ? 'save' : 'create'} route: $error',
        );
      }
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _saving = false);
    }
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
        seconds >= 60) {
      return null;
    }
    return Duration(minutes: minutes, seconds: seconds).inMilliseconds;
  }

  String _formatDuration(int? millis) {
    if (millis == null) return '';
    final seconds = millis ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _pickCarZeroDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _carZeroStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    setState(
      () => _carZeroStart = DateTime(
        date.year,
        date.month,
        date.day,
        _carZeroStart.hour,
        _carZeroStart.minute,
      ),
    );
  }

  Future<void> _pickCarZeroTime() async {
    var selectedTime = _carZeroStart;
    final time = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select car-zero start time'),
        contentPadding: const EdgeInsets.only(top: 12),
        content: SizedBox(
          height: 216,
          width: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: _carZeroStart,
            minuteInterval: 1,
            onDateTimeChanged: (value) => selectedTime = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(selectedTime),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (time == null || !mounted) return;

    setState(
      () => _carZeroStart = DateTime(
        _carZeroStart.year,
        _carZeroStart.month,
        _carZeroStart.day,
        time.hour,
        time.minute,
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.month}/${value.day}/${value.year}';

  String _formatTime(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(value));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit route' : 'New route')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Route name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a route name.'
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _timeZoneController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Time zone',
                hintText: 'America/New_York',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a time zone.'
                  : null,
            ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Car-zero start',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCarZeroDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(_carZeroStart)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCarZeroTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_formatTime(context, _carZeroStart)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _maximumScoreController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum checkpoint score',
                border: OutlineInputBorder(),
              ),
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'Enter a whole number.'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _defaultSpeedController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Default speed',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _restartIntervalController,
              enabled: !_saving,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Restart interval',
                hintText: 'Optional, mm:ss',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _defaultPauseController,
              enabled: !_saving,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Default pause',
                hintText: 'Optional, mm:ss',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _saving
                    ? (_editing ? 'Saving…' : 'Creating…')
                    : (_editing ? 'Save route' : 'Create route'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
