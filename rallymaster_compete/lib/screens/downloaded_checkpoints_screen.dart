import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/checkpoint_crossing.dart';
import '../models/competition_checkpoint.dart';
import '../models/discovered_rally.dart';
import '../services/competition_api_client.dart';
import '../services/checkpoint_crossing_store.dart';
import '../services/checkpoint_detection_service.dart';
import '../services/competition_device_identity.dart';
import '../widgets/rallymaster_compete_about_dialog.dart';
import '../widgets/precision_drive_calibration_gate.dart';

/// Temporary diagnostic UI for verifying a registered device can download its
/// checkpoint plan. The download API itself is part of the scoring workflow.
class DownloadedCheckpointsScreen extends StatefulWidget {
  const DownloadedCheckpointsScreen({
    super.key,
    required this.rally,
    required this.route,
  });

  final DiscoveredRally rally;
  final DiscoveredRoute route;

  @override
  State<DownloadedCheckpointsScreen> createState() =>
      _DownloadedCheckpointsScreenState();
}

class _DownloadedCheckpointsScreenState
    extends State<DownloadedCheckpointsScreen> {
  final _apiClient = CompetitionApiClient();
  final _crossingStore = CheckpointCrossingStore();
  late final SensorFusionService _sensorFusion;
  List<CompetitionCheckpoint>? _checkpoints;
  CheckpointDetectionService? _detector;
  Map<int, CheckpointCrossing> _crossings = {};
  String? _error;
  String? _detectionStatus;
  var _loading = true;
  var _uploadingTelemetry = false;

  @override
  void initState() {
    super.initState();
    // A competitor must be able to see the live scoring screen while driving;
    // do not let the device auto-lock during an active route.
    WakelockPlus.enable();
    _sensorFusion = SensorFusionService()
      ..start()
      ..setEnabled(true)
      ..setLowSpeedAssistEnabled(true);
    _download();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    unawaited(_detector?.dispose() ?? Future.value());
    _sensorFusion.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    await _detector?.dispose();
    _detector = null;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deviceId = await CompetitionDeviceIdentity.read();
      if (deviceId == null) throw const _CheckpointDownloadException();
      final checkpoints = await _apiClient.downloadCheckpoints(
        routeId: widget.route.id,
        deviceId: deviceId,
      );
      final crossings = await _crossingStore.load(widget.route.id);
      if (mounted) {
        setState(() {
          _checkpoints = checkpoints;
          _crossings = crossings;
          _detectionStatus = 'Starting checkpoint detection…';
        });
      }
      await _startDetection(checkpoints, crossings.values);
      // During testing, calibration begins as soon as the selected route has
      // been downloaded. The future Start Competition action will invoke this
      // at the actual event start instead.
      if (mounted) _sensorFusion.requestCalibration();
    } on CompetitionApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.statusCode == 401
              ? 'This device is not registered for the selected route.'
              : 'Unable to download checkpoints. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to download checkpoints. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startDetection(
    List<CompetitionCheckpoint> checkpoints,
    Iterable<CheckpointCrossing> crossings,
  ) async {
    final detector = CheckpointDetectionService(
      checkpoints: checkpoints,
      existingCrossings: crossings,
      onCrossing: _recordCrossing,
      sensorFusion: _sensorFusion,
    );
    _detector = detector;
    try {
      await detector.start();
      if (mounted && identical(_detector, detector)) {
        setState(() => _detectionStatus = 'Checkpoint detection active');
      }
    } on CheckpointDetectionException catch (error) {
      if (mounted && identical(_detector, detector)) {
        setState(() => _detectionStatus = error.message);
      }
    } catch (_) {
      if (mounted && identical(_detector, detector)) {
        setState(
          () => _detectionStatus = 'Unable to start checkpoint detection.',
        );
      }
    }
  }

  void _recordCrossing(CheckpointCrossing crossing) {
    if (!mounted) return;
    setState(
      () => _crossings = {..._crossings, crossing.checkpointId: crossing},
    );
    unawaited(_crossingStore.save(widget.route.id, _crossings.values));
  }

  Future<void> _uploadTelemetry() async {
    final crossings = _crossings.values
        .where((crossing) => crossing.samples.isNotEmpty)
        .toList(growable: false);
    if (crossings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No checkpoint telemetry is available yet.'),
        ),
      );
      return;
    }
    setState(() => _uploadingTelemetry = true);
    try {
      final deviceId = await CompetitionDeviceIdentity.read();
      if (deviceId == null) throw const _CheckpointDownloadException();
      final result = await _apiClient.uploadTelemetry(
        routeId: widget.route.id,
        deviceId: deviceId,
        crossings: crossings,
      );
      if (!mounted) return;
      final message = result.accepted == 0
          ? 'Telemetry was already uploaded.'
          : 'Uploaded ${result.accepted} checkpoint telemetry record${result.accepted == 1 ? '' : 's'}.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on CompetitionApiException catch (error) {
      if (!mounted) return;
      final message = error.statusCode == 401
          ? 'This device is not registered for the selected route.'
          : 'Unable to upload telemetry. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to upload telemetry. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingTelemetry = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrecisionDriveCalibrationGate(
    sensorFusion: _sensorFusion,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded checkpoints'),
        actions: [
          PopupMenuButton<_CheckpointMenuAction>(
            tooltip: 'Menu',
            icon: const Icon(Icons.settings_outlined),
            onSelected: (action) {
              switch (action) {
                case _CheckpointMenuAction.recalibratePrecisionDrive:
                  _sensorFusion.requestCalibration();
                case _CheckpointMenuAction.uploadTelemetry:
                  _uploadTelemetry();
                case _CheckpointMenuAction.about:
                  showDialog<void>(
                    context: context,
                    builder: (_) => const RallyMasterCompeteAboutDialog(),
                  );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _CheckpointMenuAction.recalibratePrecisionDrive,
                child: Text('Recalibrate PrecisionDrive'),
              ),
              PopupMenuItem(
                value: _CheckpointMenuAction.uploadTelemetry,
                enabled: !_uploadingTelemetry,
                child: Text(
                  _uploadingTelemetry
                      ? 'Uploading telemetry…'
                      : 'Upload telemetry',
                ),
              ),
              const PopupMenuItem(
                value: _CheckpointMenuAction.about,
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    ),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading checkpoints…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final checkpoints = _checkpoints!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          padding: const EdgeInsets.all(12),
          child: const Text(
            'TESTING ONLY — downloaded checkpoint plan',
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('${widget.rally.name} — ${widget.route.name}'),
        ),
        if (_detectionStatus != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _detectionStatus!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: checkpoints.isEmpty
              ? const Center(child: Text('No checkpoints were downloaded.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No.')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Distance')),
                        DataColumn(label: Text('Latitude')),
                        DataColumn(label: Text('Longitude')),
                        DataColumn(label: Text('Crossed')),
                        DataColumn(label: Text('Crossed at')),
                      ],
                      rows: checkpoints.map(_row).toList(growable: false),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  DataRow _row(CompetitionCheckpoint checkpoint) => DataRow(
    color: _crossings.containsKey(checkpoint.id)
        ? WidgetStatePropertyAll(
            Theme.of(context).colorScheme.secondaryContainer,
          )
        : null,
    cells: [
      DataCell(Text(checkpoint.number?.toString() ?? '—')),
      DataCell(Text(_formatType(checkpoint.type))),
      DataCell(
        Text(checkpoint.name?.isNotEmpty == true ? checkpoint.name! : '—'),
      ),
      DataCell(
        Text(
          checkpoint.distance == null
              ? '—'
              : '${checkpoint.distance!.toStringAsFixed(3)} mi',
        ),
      ),
      DataCell(Text(checkpoint.latitude?.toStringAsFixed(6) ?? '—')),
      DataCell(Text(checkpoint.longitude?.toStringAsFixed(6) ?? '—')),
      DataCell(
        Icon(
          _crossings.containsKey(checkpoint.id)
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: _crossings.containsKey(checkpoint.id)
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      DataCell(Text(_formatCrossingTime(_crossings[checkpoint.id]))),
    ],
  );

  String _formatType(String type) => type
      .split('_')
      .map((word) => '${word[0]}${word.substring(1).toLowerCase()}')
      .join(' ');

  String _formatCrossingTime(CheckpointCrossing? crossing) {
    if (crossing == null) return '—';
    final time = crossing.occurredAt;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }
}

class _CheckpointDownloadException implements Exception {
  const _CheckpointDownloadException();
}

enum _CheckpointMenuAction { recalibratePrecisionDrive, uploadTelemetry, about }
