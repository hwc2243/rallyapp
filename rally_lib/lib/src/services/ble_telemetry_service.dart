import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as peripheral;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/controller_command.dart';
import '../models/ble_controller_device.dart';
import '../models/device_role.dart';
import '../models/live_telemetry.dart';

/// Stable GATT UUIDs used by every Rally Controller peripheral.
class RallyBleGatt {
  static const serviceUuid = '0000FA10-0000-1000-8000-00805F9B34FB';
  static const telemetryCharacteristicUuid =
      '0000FA11-0000-1000-8000-00805F9B34FB';
  static const commandCharacteristicUuid =
      '0000FA12-0000-1000-8000-00805F9B34FB';
  static const frequencyCharacteristicUuid =
      '0000FA13-0000-1000-8000-00805F9B34FB';
}

/// Live Controller peripheral status, exposed for in-app diagnostics.
class ControllerBleStatus {
  const ControllerBleStatus({
    required this.bluetoothPoweredOn,
    required this.isAdvertising,
    this.error,
  });

  final bool bluetoothPoweredOn;
  final bool isAdvertising;
  final String? error;
}

/// Latest central/client connection stage, retained for support diagnostics.
class BleConnectionDiagnostic {
  const BleConnectionDiagnostic({
    required this.stage,
    required this.detail,
    required this.timestamp,
  });

  final String stage;
  final String detail;
  final DateTime timestamp;

  String get displayText => '[${timestamp.toIso8601String()}] $stage\n$detail';
}

/// Sends the most recent telemetry at a selected, bounded BLE packet rate.
class BleTelemetryPublisher {
  BleTelemetryPublisher({int frequencyHz = 10}) {
    setFrequency(frequencyHz);
  }

  final _packets = StreamController<List<int>>.broadcast();
  Timer? _timer;
  LiveTelemetry? _latest;
  int _frequencyHz = 10;
  int _packetSequence = 0;
  bool _isEmitting = false;

  Stream<List<int>> get packets => _packets.stream;
  int get frequencyHz => _frequencyHz;

  void setFrequency(int value) {
    if (!const {5, 10, 20}.contains(value)) {
      throw ArgumentError.value(
          value, 'value', 'BLE frequency must be 5, 10, or 20 Hz');
    }
    _frequencyHz = value;
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ value),
      (_) => _emitLatest(),
    );
  }

  Future<void> _emitLatest() async {
    if (_isEmitting) return;
    final telemetry = _latest;
    if (telemetry == null) return;
    _isEmitting = true;
    try {
      final payload = utf8.encode(jsonEncode(telemetry.toJson()));
      for (final fragment in _BlePacketFramer.fragment(
        payload,
        _packetSequence++ & 0xff,
      )) {
        _packets.add(fragment);
        // iOS has a finite CBPeripheralManager notification queue. A short
        // gap allows each notification to drain before the next fragment.
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
    } finally {
      _isEmitting = false;
    }
  }

  void publish(LiveTelemetry telemetry) => _latest = telemetry;
  Future<void> dispose() async {
    _timer?.cancel();
    await _packets.close();
  }
}

/// Frames packets below the negotiated Android central MTU. FlutterBluePlus
/// requests 512 bytes on connect; 180 bytes leaves room for BLE overhead.
/// The header is `RL`, sequence, fragment index, fragment count.
class _BlePacketFramer {
  static const _markerA = 0x52;
  static const _markerB = 0x4c;
  static const _headerLength = 5;
  static const _maxNotificationLength = 180;

  static Iterable<List<int>> fragment(List<int> payload, int sequence) sync* {
    const payloadLength = _maxNotificationLength - _headerLength;
    final count = (payload.length / payloadLength).ceil();
    for (var index = 0; index < count; index++) {
      final start = index * payloadLength;
      final end = (start + payloadLength).clamp(0, payload.length);
      yield [
        _markerA,
        _markerB,
        sequence,
        index,
        count,
        ...payload.sublist(start, end),
      ];
    }
  }

  static bool isFragment(List<int> value) =>
      value.length >= _headerLength &&
      value[0] == _markerA &&
      value[1] == _markerB;
}

/// BLE GATT server for Controller and central/client transport for Driver and
/// Navigator roles.
class BleTelemetryService {
  static const _roleKey = 'device_role';
  static const _frequencyKey = 'ble_frequency_hz';
  static const _pairedControllerKey = 'paired_controller_id';

  BleTelemetryService(this._prefs)
      : publisher = BleTelemetryPublisher(
          frequencyHz: _readFrequency(_prefs),
        );

  final SharedPreferences _prefs;
  final BleTelemetryPublisher publisher;
  final _telemetry = StreamController<LiveTelemetry>.broadcast();
  final _commands = StreamController<ControllerCommand>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _controllerStatus = StreamController<ControllerBleStatus>.broadcast();
  final _connectionDiagnostics =
      StreamController<BleConnectionDiagnostic>.broadcast();
  StreamSubscription<List<int>>? _telemetrySubscription;
  StreamSubscription<List<int>>? _commandSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _controllerPacketSubscription;
  Timer? _telemetryTimeout;
  BluetoothDevice? _controller;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _frequencyCharacteristic;
  bool _isDisposed = false;
  bool _controllerGattStarted = false;
  bool _bluetoothPoweredOn = false;
  bool _isAdvertising = false;
  String? _advertisingError;
  bool _peripheralCallbacksConfigured = false;
  Completer<void>? _serviceAddedCompleter;
  final Map<String, BytesBuilder> _commandBuffers = {};
  BytesBuilder? _telemetryBuffer;
  int? _telemetrySequence;
  int _nextTelemetryFragment = 0;
  BleConnectionDiagnostic _connectionDiagnostic = BleConnectionDiagnostic(
    stage: 'Waiting for Controller',
    detail: 'No connection attempt has started.',
    timestamp: DateTime.now(),
  );

  Stream<LiveTelemetry> get telemetry => _telemetry.stream;
  Stream<ControllerCommand> get commands => _commands.stream;
  Stream<bool> get connectionState => _connection.stream;
  Stream<BleConnectionDiagnostic> get connectionDiagnostics =>
      _connectionDiagnostics.stream;
  BleConnectionDiagnostic get connectionDiagnosticSnapshot =>
      _connectionDiagnostic;
  Stream<ControllerBleStatus> get controllerStatus => _controllerStatus.stream;
  ControllerBleStatus get controllerStatusSnapshot => ControllerBleStatus(
        bluetoothPoweredOn: _bluetoothPoweredOn,
        isAdvertising: _isAdvertising,
        error: _advertisingError,
      );
  DeviceRole get role =>
      DeviceRoleStorage.fromStorage(_prefs.getString(_roleKey));
  int get frequencyHz => publisher.frequencyHz;
  String? get pairedControllerId => _prefs.getString(_pairedControllerKey);

  static int _readFrequency(SharedPreferences prefs) {
    final value = prefs.getInt(_frequencyKey) ?? 10;
    return const {5, 10, 20}.contains(value) ? value : 10;
  }

  Future<void> setRole(DeviceRole role) async {
    await _prefs.setString(_roleKey, role.storageValue);
    if (role == DeviceRole.controller) {
      await startControllerAdvertising();
    } else {
      await stopControllerAdvertising();
      await disconnect();
    }
  }

  /// Hosts the Controller GATT service and broadcasts each throttled packet to
  /// every subscribed Driver and Navigator central.
  Future<void> startControllerAdvertising() async {
    if (_controllerGattStarted && _isAdvertising) return;
    _configurePeripheralCallbacks();
    _advertisingError = null;
    _emitControllerStatus();
    try {
      await peripheral.BlePeripheral.initialize();
      if (!await peripheral.BlePeripheral.isSupported()) {
        throw StateError(
            'BLE peripheral mode is not supported on this device.');
      }
      await peripheral.BlePeripheral.clearServices();
      final serviceAdded = Completer<void>();
      _serviceAddedCompleter = serviceAdded;
      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: RallyBleGatt.serviceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: RallyBleGatt.telemetryCharacteristicUuid,
              properties: [peripheral.CharacteristicProperties.notify.index],
              permissions: [peripheral.AttributePermissions.readable.index],
            ),
            peripheral.BleCharacteristic(
              uuid: RallyBleGatt.commandCharacteristicUuid,
              properties: [
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
              ],
              permissions: [peripheral.AttributePermissions.writeable.index],
            ),
          ],
        ),
      );
      await serviceAdded.future.timeout(const Duration(seconds: 5));
      _serviceAddedCompleter = null;
      peripheral.BlePeripheral.setWriteRequestCallback(_onGattWrite);
      _controllerPacketSubscription ??= publisher.packets.listen((packet) {
        peripheral.BlePeripheral.updateCharacteristic(
          characteristicId: RallyBleGatt.telemetryCharacteristicUuid,
          value: Uint8List.fromList(packet),
        );
      });
      await peripheral.BlePeripheral.startAdvertising(
        services: [RallyBleGatt.serviceUuid],
        localName: 'RallyController',
      );
      _controllerGattStarted = true;
    } catch (error) {
      _serviceAddedCompleter = null;
      _controllerGattStarted = false;
      _isAdvertising = false;
      _advertisingError = error.toString();
      _emitControllerStatus();
    }
  }

  Future<void> restartControllerAdvertising() async {
    await stopControllerAdvertising();
    await startControllerAdvertising();
  }

  void _configurePeripheralCallbacks() {
    if (_peripheralCallbacksConfigured) return;
    _peripheralCallbacksConfigured = true;
    peripheral.BlePeripheral.setBleStateChangeCallback((poweredOn) {
      _bluetoothPoweredOn = poweredOn;
      if (!poweredOn) _isAdvertising = false;
      _emitControllerStatus();
    });
    peripheral.BlePeripheral.setAdvertisingStatusUpdateCallback((
      advertising,
      error,
    ) {
      _isAdvertising = advertising;
      _advertisingError = error;
      if (!advertising && error != null) _controllerGattStarted = false;
      _emitControllerStatus();
    });
    peripheral.BlePeripheral.setServiceAddedCallback((_, error) {
      final completer = _serviceAddedCompleter;
      if (error != null) {
        _advertisingError = error;
        _emitControllerStatus();
        if (completer != null && !completer.isCompleted) {
          completer.completeError(StateError(error));
        }
      } else if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    });
  }

  void _emitControllerStatus() {
    if (!_controllerStatus.isClosed) {
      _controllerStatus.add(controllerStatusSnapshot);
    }
  }

  peripheral.WriteRequestResult? _onGattWrite(
    String deviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId != RallyBleGatt.commandCharacteristicUuid ||
        value == null) {
      return peripheral.WriteRequestResult(status: 0);
    }
    final buffer = _commandBuffers.putIfAbsent(deviceId, BytesBuilder.new);
    if (offset == 0 && buffer.length > 0) buffer.clear();
    buffer.add(value);
    try {
      final command = ControllerCommand.fromJson(
        jsonDecode(utf8.decode(buffer.toBytes())) as Map<String, dynamic>,
      );
      _commands.add(command);
      _commandBuffers.remove(deviceId);
    } on FormatException {
      // A long write can arrive in several ATT fragments; retain its bytes.
    }
    return peripheral.WriteRequestResult(status: 0);
  }

  Future<void> stopControllerAdvertising() async {
    await _controllerPacketSubscription?.cancel();
    _controllerPacketSubscription = null;
    if (_controllerGattStarted) {
      await peripheral.BlePeripheral.stopAdvertising();
      await peripheral.BlePeripheral.clearServices();
      _controllerGattStarted = false;
    }
    _isAdvertising = false;
    _advertisingError = null;
    _emitControllerStatus();
    _commandBuffers.clear();
  }

  Future<void> setFrequency(int frequencyHz) async {
    publisher.setFrequency(frequencyHz);
    await _prefs.setInt(_frequencyKey, frequencyHz);
    final characteristic = _frequencyCharacteristic;
    if (characteristic != null) {
      await characteristic.write(utf8.encode('$frequencyHz'),
          withoutResponse: false);
    }
  }

  Stream<List<ScanResult>> scanForControllers() async* {
    _setConnectionDiagnostic(
      'Scanning',
      'Scanning nearby BLE devices for RallyController.',
    );
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
    );
    yield* FlutterBluePlus.scanResults.map((results) {
      final controllers = results.where(_isRallyController).toList();
      _setConnectionDiagnostic(
        'Scanning',
        'Found ${results.length} nearby device(s); '
            '${controllers.length} RallyController candidate(s).',
      );
      return controllers;
    });
  }

  bool _isRallyController(ScanResult result) {
    final advertisedName = result.advertisementData.advName.toLowerCase();
    final deviceName = result.device.advName.toLowerCase();
    final hasRallyService = result.advertisementData.serviceUuids.contains(
      Guid(RallyBleGatt.serviceUuid),
    );
    return hasRallyService ||
        advertisedName == 'rallycontroller' ||
        deviceName == 'rallycontroller';
  }

  Stream<List<BleControllerDevice>> scanForControllerDevices() {
    return scanForControllers().map((results) => results.map((result) {
          return BleControllerDevice(
            id: result.device.remoteId.str,
            name: result.advertisementData.advName.isNotEmpty
                ? result.advertisementData.advName
                : result.device.platformName.isEmpty
                    ? 'Rally Controller'
                    : result.device.platformName,
            rssi: result.rssi,
          );
        }).toList(growable: false));
  }

  Future<void> pair(BluetoothDevice controller) async {
    _setConnectionDiagnostic(
      'Pairing',
      'Connecting to Controller ${controller.remoteId.str}.',
    );
    await _connect(controller);
    await _prefs.setString(_pairedControllerKey, controller.remoteId.str);
    _setConnectionDiagnostic(
      'Paired',
      'Connected and saved Controller ${controller.remoteId.str}.',
    );
  }

  Future<void> pairControllerId(String id) =>
      pair(BluetoothDevice(remoteId: DeviceIdentifier(id)));

  Future<void> reconnect() async {
    final id = pairedControllerId;
    if (id == null || id.isEmpty) {
      _setConnectionDiagnostic(
        'No paired Controller',
        'Open Device Role & Bluetooth and select RallyController.',
      );
      return;
    }
    _setConnectionDiagnostic(
        'Reconnecting', 'Connecting to saved Controller $id.');
    await _connect(BluetoothDevice(remoteId: DeviceIdentifier(id)));
  }

  Future<void> _connect(BluetoothDevice controller) async {
    try {
      await disconnect();
      await stopControllerAdvertising();
      _controller = controller;
      _setConnectionDiagnostic(
          'Connecting', 'Opening BLE link to ${controller.remoteId.str}.');
      // Android GATT connections are unreliable while a hardware scan remains
      // active. Stop it explicitly before opening the connection.
      await FlutterBluePlus.stopScan();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await controller.connect(autoConnect: false);
      _connectionSubscription = controller.connectionState.listen((state) {
        final connected = state == BluetoothConnectionState.connected;
        _connection.add(connected);
        _setConnectionDiagnostic(
          connected ? 'Connected' : 'Disconnected',
          'BLE connection state: ${state.name}.',
        );
        if (!connected && !_isDisposed && role != DeviceRole.controller) {
          Future<void>.delayed(const Duration(seconds: 2), reconnect);
        }
      });
      _setConnectionDiagnostic(
          'Discovering GATT', 'Reading Controller services.');
      final services = await controller.discoverServices();
      final discoveredUuids =
          services.map((service) => service.uuid.toString()).join(', ');
      final rallyServices = services
          .where(
              (candidate) => candidate.uuid == Guid(RallyBleGatt.serviceUuid))
          .toList(growable: false);
      if (rallyServices.isEmpty) {
        throw StateError(
          'Controller GATT service ${RallyBleGatt.serviceUuid} was not found. '
          'Android discovered: ${discoveredUuids.isEmpty ? 'none' : discoveredUuids}',
        );
      }
      final service = rallyServices.single;
      final discoveredCharacteristics = service.characteristics
          .map((item) => item.uuid.toString())
          .join(', ');
      final telemetryCharacteristics = service.characteristics
          .where(
            (candidate) =>
                candidate.uuid ==
                Guid(RallyBleGatt.telemetryCharacteristicUuid),
          )
          .toList(growable: false);
      if (telemetryCharacteristics.isEmpty) {
        throw StateError(
          'Telemetry characteristic ${RallyBleGatt.telemetryCharacteristicUuid} '
          'was not found. Controller service characteristics: '
          '${discoveredCharacteristics.isEmpty ? 'none' : discoveredCharacteristics}',
        );
      }
      final commandCharacteristics = service.characteristics
          .where(
            (candidate) =>
                candidate.uuid == Guid(RallyBleGatt.commandCharacteristicUuid),
          )
          .toList(growable: false);
      if (commandCharacteristics.isEmpty) {
        throw StateError(
          'Command characteristic ${RallyBleGatt.commandCharacteristicUuid} '
          'was not found. Controller service characteristics: '
          '${discoveredCharacteristics.isEmpty ? 'none' : discoveredCharacteristics}',
        );
      }
      final telemetryCharacteristic = telemetryCharacteristics.single;
      _commandCharacteristic = commandCharacteristics.single;
      final frequencyCharacteristics = service.characteristics.where(
        (candidate) =>
            candidate.uuid == Guid(RallyBleGatt.frequencyCharacteristicUuid),
      );
      _frequencyCharacteristic = frequencyCharacteristics.isEmpty
          ? null
          : frequencyCharacteristics.first;
      _setConnectionDiagnostic(
        'Subscribing to telemetry',
        'Service found. Enabling notifications on ${telemetryCharacteristic.uuid}.',
      );
      await telemetryCharacteristic.setNotifyValue(true);
      _telemetrySubscription = telemetryCharacteristic.lastValueStream.listen(
        _onTelemetryNotification,
        onError: (Object error) => _setConnectionDiagnostic(
          'Telemetry notification error',
          error.toString(),
        ),
      );
      _telemetryTimeout?.cancel();
      _telemetryTimeout = Timer(const Duration(seconds: 5), () {
        _setConnectionDiagnostic(
          'Connected, waiting for telemetry',
          'GATT subscription succeeded but no telemetry arrived in 5 seconds. '
              'Keep the Controller app open and verify its BLE status.',
        );
      });
      _setConnectionDiagnostic(
        'Ready',
        'Connected to ${controller.remoteId.str}. Services: $discoveredUuids',
      );
    } catch (error) {
      final message = error.toString();
      final detail = message.contains('android-code: 111')
          ? '$message\n\nAndroid BLE link failed before GATT discovery. '
              'Disconnect this Controller from nRF Connect, stop scanning in '
              'other BLE apps, tap Restart Advertising on the iPhone, then '
              'retry from within 1–2 metres.'
          : message;
      _setConnectionDiagnostic('Connection failed', detail);
      rethrow;
    }
  }

  void _onTelemetryNotification(List<int> bytes) {
    if (bytes.isEmpty) return;
    if (!_BlePacketFramer.isFragment(bytes)) {
      _decodeTelemetry(bytes);
      return;
    }

    final sequence = bytes[2];
    final index = bytes[3];
    final count = bytes[4];
    if (count == 0 || index >= count) return;
    if (index == 0) {
      _telemetrySequence = sequence;
      _nextTelemetryFragment = 0;
      _telemetryBuffer = BytesBuilder(copy: false);
    }
    final buffer = _telemetryBuffer;
    if (buffer == null ||
        _telemetrySequence != sequence ||
        index != _nextTelemetryFragment) {
      return;
    }
    buffer.add(bytes.sublist(_BlePacketFramer._headerLength));
    _nextTelemetryFragment++;
    if (_nextTelemetryFragment == count) {
      _telemetryBuffer = null;
      _decodeTelemetry(buffer.toBytes());
    }
  }

  void _decodeTelemetry(List<int> bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _telemetry.add(LiveTelemetry.fromJson(map));
      _telemetryTimeout?.cancel();
      _setConnectionDiagnostic(
        'Receiving telemetry',
        'Live telemetry packets are arriving.',
      );
    } catch (error) {
      _setConnectionDiagnostic('Telemetry decode failed', error.toString());
    }
  }

  void _setConnectionDiagnostic(String stage, String detail) {
    _connectionDiagnostic = BleConnectionDiagnostic(
      stage: stage,
      detail: detail,
      timestamp: DateTime.now(),
    );
    if (!_connectionDiagnostics.isClosed) {
      _connectionDiagnostics.add(_connectionDiagnostic);
    }
  }

  Future<void> sendCommand(ControllerCommand command) async {
    final characteristic = _commandCharacteristic;
    if (characteristic == null) {
      throw StateError('No Controller command characteristic is connected');
    }
    await characteristic.write(utf8.encode(jsonEncode(command.toJson())),
        withoutResponse: false);
  }

  Future<void> disconnect() async {
    await _telemetrySubscription?.cancel();
    _telemetryTimeout?.cancel();
    await _commandSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _telemetrySubscription = null;
    _commandSubscription = null;
    _connectionSubscription = null;
    final controller = _controller;
    _controller = null;
    _commandCharacteristic = null;
    _frequencyCharacteristic = null;
    _telemetryBuffer = null;
    _telemetrySequence = null;
    _nextTelemetryFragment = 0;
    if (controller != null) await controller.disconnect();
    _connection.add(false);
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await disconnect();
    await stopControllerAdvertising();
    await publisher.dispose();
    await _telemetry.close();
    await _commands.close();
    await _connection.close();
    await _controllerStatus.close();
    await _connectionDiagnostics.close();
  }
}
