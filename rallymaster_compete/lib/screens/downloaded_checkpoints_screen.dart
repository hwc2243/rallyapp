import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/checkpoint_crossing.dart';
import '../models/checkpoint_score.dart';
import '../models/competition_checkpoint.dart';
import '../models/competition_route_package.dart';
import '../models/discovered_rally.dart';
import '../models/time_allowance.dart';
import '../services/competition_api_client.dart';
import '../services/checkpoint_crossing_store.dart';
import '../services/checkpoint_detection_service.dart';
import '../services/checkpoint_scoring_service.dart';
import '../services/competition_device_identity.dart';
import '../services/time_allowance_store.dart';
import '../widgets/rallymaster_compete_about_dialog.dart';
import '../widgets/precision_drive_calibration_gate.dart';

/// Temporary diagnostic UI for verifying a registered device can download its
/// checkpoint plan. The download API itself is part of the scoring workflow.
class DownloadedCheckpointsScreen extends StatefulWidget {
  const DownloadedCheckpointsScreen({
    super.key,
    required this.rally,
    required this.route,
    required this.carNumber,
  });

  final DiscoveredRally rally;
  final DiscoveredRoute route;
  final int carNumber;

  @override
  State<DownloadedCheckpointsScreen> createState() =>
      _DownloadedCheckpointsScreenState();
}

class _DownloadedCheckpointsScreenState
    extends State<DownloadedCheckpointsScreen> {
  final _apiClient = CompetitionApiClient();
  final _crossingStore = CheckpointCrossingStore();
  final _timeAllowanceStore = TimeAllowanceStore();
  final _scoringService = const CheckpointScoringService();
  late final SensorFusionService _sensorFusion;
  List<CompetitionCheckpoint>? _checkpoints;
  CompetitionRoutePackage? _routePackage;
  CheckpointDetectionService? _detector;
  Map<int, CheckpointCrossing> _crossings = {};
  List<TimeAllowance> _allowances = const [];
  Map<int, CheckpointScore> _scores = const {};
  String? _error;
  String? _detectionStatus;
  var _loading = true;
  var _uploadingTelemetry = false;
  var _calibrationRequestedAfterStart = false;

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
    _calibrationRequestedAfterStart = false;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deviceId = await CompetitionDeviceIdentity.read();
      if (deviceId == null) throw const _CheckpointDownloadException();
      final routePackage = await _apiClient.downloadRoutePackage(
        routeId: widget.route.id,
        deviceId: deviceId,
      );
      final checkpoints = routePackage.checkpoints;
      final crossings = await _crossingStore.load(widget.route.id);
      final allowances = await _timeAllowanceStore.load(widget.route.id);
      if (mounted) {
        setState(() {
          _routePackage = routePackage;
          _checkpoints = checkpoints;
          _crossings = crossings;
          _allowances = allowances;
          _scores = _calculateScores(routePackage, crossings, allowances);
          _detectionStatus = 'Starting checkpoint detection…';
        });
      }
      await _startDetection(
        checkpoints,
        crossings.values,
        routePackage.acquisitionRadiusMeters,
      );
      // START can be recorded on a previous app run. In that case, this new
      // SensorFusionService still needs calibration, but only after the
      // confirmed START crossing—not while a person is walking to it.
      if (_hasRegisteredStart(checkpoints, crossings)) {
        _requestCalibrationAfterStart();
      }
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
    double acquisitionRadiusMeters,
  ) async {
    final detector = CheckpointDetectionService(
      checkpoints: checkpoints,
      existingCrossings: crossings,
      onCrossing: _recordCrossing,
      sensorFusion: _sensorFusion,
      acquisitionRadiusMeters: acquisitionRadiusMeters,
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
    final crossings = {..._crossings, crossing.checkpointId: crossing};
    setState(() {
      _crossings = crossings;
      final routePackage = _routePackage;
      if (routePackage != null) {
        _scores = _calculateScores(routePackage, crossings, _allowances);
      }
    });
    unawaited(_crossingStore.save(widget.route.id, _crossings.values));
    if (_isStartCheckpoint(crossing.checkpointId)) {
      _requestCalibrationAfterStart();
    }
  }

  bool _hasRegisteredStart(
    Iterable<CompetitionCheckpoint> checkpoints,
    Map<int, CheckpointCrossing> crossings,
  ) => checkpoints.any(
    (checkpoint) =>
        checkpoint.type == 'START' && crossings.containsKey(checkpoint.id),
  );

  bool _isStartCheckpoint(int checkpointId) =>
      _checkpoints?.any(
        (checkpoint) =>
            checkpoint.id == checkpointId && checkpoint.type == 'START',
      ) ??
      false;

  void _requestCalibrationAfterStart() {
    if (_calibrationRequestedAfterStart || !mounted) return;
    _calibrationRequestedAfterStart = true;
    _sensorFusion.requestCalibration();
    setState(() {
      _detectionStatus = 'START registered. Mount the phone and calibrate PrecisionDrive before continuing.';
    });
  }

  Map<int, CheckpointScore> _calculateScores(
    CompetitionRoutePackage routePackage,
    Map<int, CheckpointCrossing> crossings,
    List<TimeAllowance> allowances,
  ) => _scoringService.calculate(
    routePackage: routePackage,
    carNumber: widget.carNumber,
    crossings: crossings.values,
    allowances: allowances,
  );

  Future<void> _addTimeAllowance(Duration duration) async {
    final checkpoints = _checkpoints;
    final routePackage = _routePackage;
    if (checkpoints == null || routePackage == null) return;
    final effectiveAfterPosition = checkpoints
        .where((checkpoint) => _crossings.containsKey(checkpoint.id))
        .fold<int>(
          0,
          (latest, checkpoint) =>
              checkpoint.routePosition != null &&
                  checkpoint.routePosition! > latest
              ? checkpoint.routePosition!
              : latest,
        );
    final allowances = [
      ..._allowances,
      TimeAllowance(
        millis: duration.inMilliseconds,
        effectiveAfterRoutePosition: effectiveAfterPosition,
      ),
    ];
    setState(() {
      _allowances = allowances;
      _scores = _calculateScores(routePackage, _crossings, allowances);
    });
    await _timeAllowanceStore.save(widget.route.id, allowances);
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
          child: Text(
            '${widget.rally.name} — ${widget.route.name}  •  Car ${widget.carNumber}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _addTimeAllowance(const Duration(seconds: 30)),
                  child: const Text('TA +0.5 min'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _addTimeAllowance(const Duration(minutes: 1)),
                  child: const Text('TA +1.0 min'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Score: ${_scores.values.fold<int>(0, (total, score) => total + score.points)}'
            '${_allowances.isEmpty ? '' : '  •  TA: ${_formatTaTotal()}'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                        DataColumn(label: Text('Expected')),
                        DataColumn(label: Text('Score')),
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
      DataCell(Text(_formatExpectedTime(_scores[checkpoint.id]))),
      DataCell(Text(_scores[checkpoint.id]?.points.toString() ?? '—')),
    ],
  );

  String _formatTaTotal() {
    final seconds = _allowances.fold<int>(
      0,
      (total, allowance) => total + allowance.millis ~/ 1000,
    );
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _formatExpectedTime(CheckpointScore? score) {
    if (score == null) return '—';
    final time = score.expectedArrival;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

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
