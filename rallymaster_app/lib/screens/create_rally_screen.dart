import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/rally_settings.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/rally_provider.dart';
import '../providers/tenant_discriminator_provider.dart';

class CreateRallyScreen extends StatefulWidget {
  const CreateRallyScreen({
    super.key,
    required this.session,
    required this.accessToken,
    this.rally,
  });

  final AppSession session;
  final Future<String> Function() accessToken;
  final RallyDto? rally;

  @override
  State<CreateRallyScreen> createState() => _CreateRallyScreenState();
}

class _CreateRallyScreenState extends State<CreateRallyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _carStartIntervalController = TextEditingController(text: '1:00');
  final _defaultSpeedController = TextEditingController();
  final _restartIntervalController = TextEditingController();
  final _defaultPauseController = TextEditingController();
  late DateTime _date = DateUtils.dateOnly(DateTime.now());
  String _distanceUnit = 'MILES';
  String _scoringUnit = 'SECONDS';
  var _saving = false;
  var _loadingSettings = false;
  String? _error;

  bool get _isEditing => widget.rally != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _carStartIntervalController.dispose();
    _defaultSpeedController.dispose();
    _restartIntervalController.dispose();
    _defaultPauseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final rally = widget.rally;
    if (rally == null) return;
    _nameController.text = rally.name ?? '';
    _descriptionController.text = rally.description ?? '';
    _date = DateUtils.dateOnly(DateTime.tryParse(rally.date ?? '') ?? _date);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final rallyId = widget.rally?.serverId;
    if (rallyId == null) return;
    setState(() {
      _loadingSettings = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RallyProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RallyProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final settings = await provider.getSettings(rallyId);
      if (!mounted) return;
      setState(() {
        _distanceUnit = settings.distanceUnit;
        _scoringUnit = settings.scoringUnit;
        _carStartIntervalController.text = _formatDuration(
          settings.carStartIntervalMillis,
        );
        _defaultSpeedController.text = settings.defaultSpeed?.toString() ?? '';
        _restartIntervalController.text =
            settings.defaultRestartIntervalMillis == null
            ? ''
            : _formatDuration(settings.defaultRestartIntervalMillis!);
        _defaultPauseController.text =
            settings.defaultPauseDurationMillis == null
            ? ''
            : _formatDuration(settings.defaultPauseDurationMillis!);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to load rally settings: $error');
      }
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RallyProvider? provider;
    try {
      final carStartInterval = _parseDuration(_carStartIntervalController.text);
      final restartInterval = _parseDuration(_restartIntervalController.text);
      final defaultPause = _parseDuration(_defaultPauseController.text);
      final defaultSpeed = _optionalDouble(_defaultSpeedController.text);
      if (carStartInterval == null ||
          carStartInterval <= 0 ||
          (_restartIntervalController.text.trim().isNotEmpty &&
              restartInterval == null) ||
          (_defaultPauseController.text.trim().isNotEmpty &&
              defaultPause == null) ||
          (_defaultSpeedController.text.trim().isNotEmpty &&
              defaultSpeed == null)) {
        throw const FormatException(
          'Enter durations as mm:ss and use non-negative numbers.',
        );
      }
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RallyProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final rally = RallyDto(
        serverId: widget.rally?.serverId,
        id: widget.rally?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _formatDate(_date),
        userId: _currentUserId,
      ).forOrganizationId(widget.session.organizationId);
      final savedRally = _isEditing
          ? await provider.update(widget.rally!.serverId!, rally)
          : await provider.create(rally);
      final rallyId = savedRally.serverId;
      if (rallyId == null)
        throw StateError('The server did not return a rally id.');
      await provider.saveSettings(
        rallyId,
        RallySettings(
          distanceUnit: _distanceUnit,
          scoringUnit: _scoringUnit,
          carStartIntervalMillis: carStartInterval,
          defaultSpeed: defaultSpeed,
          defaultRestartIntervalMillis: restartInterval,
          defaultPauseDurationMillis: defaultPause,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(savedRally);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to ${_isEditing ? 'update' : 'create'} rally: $error',
        );
      }
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _formatDuration(int value) {
    final duration = Duration(milliseconds: value);
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
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

  int get _currentUserId {
    final userId = widget.session.user.serverId;
    if (userId == null) {
      throw StateError('The authenticated user has no server id.');
    }
    return userId;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEditing ? 'Edit rally' : 'New rally')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              enabled: !_saving && !_loadingSettings,
              decoration: const InputDecoration(
                labelText: 'Rally name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a rally name.'
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving && !_loadingSettings,
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
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Rally date',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_formatDate(_date))),
                  TextButton.icon(
                    onPressed: _saving || _loadingSettings ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Choose date'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rally defaults',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _distanceUnit,
              decoration: const InputDecoration(
                labelText: 'Distance unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'MILES', child: Text('Miles')),
                DropdownMenuItem(
                  value: 'KILOMETERS',
                  child: Text('Kilometers'),
                ),
              ],
              onChanged: _saving || _loadingSettings
                  ? null
                  : (value) => setState(() => _distanceUnit = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _scoringUnit,
              decoration: const InputDecoration(
                labelText: 'Scoring unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'SECONDS', child: Text('Seconds')),
                DropdownMenuItem(
                  value: 'CENTS',
                  child: Text('Hundredths of a minute (cents)'),
                ),
              ],
              onChanged: _saving || _loadingSettings
                  ? null
                  : (value) => setState(() => _scoringUnit = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carStartIntervalController,
              enabled: !_saving && !_loadingSettings,
              decoration: const InputDecoration(
                labelText: 'Car start interval',
                hintText: 'mm:ss',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _defaultSpeedController,
              enabled: !_saving && !_loadingSettings,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Default rally speed',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _restartIntervalController,
              enabled: !_saving && !_loadingSettings,
              decoration: const InputDecoration(
                labelText: 'Default restart interval',
                hintText: 'Optional, mm:ss',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _defaultPauseController,
              enabled: !_saving && !_loadingSettings,
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
              onPressed: _saving || _loadingSettings ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(
                _saving
                    ? (_isEditing ? 'Saving…' : 'Creating…')
                    : (_isEditing ? 'Save changes' : 'Create rally'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
