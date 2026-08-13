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
  static const telemetryCharacteristicUuid = '0000FA11-0000-1000-8000-00805F9B34FB';
  static const commandCharacteristicUuid = '0000FA12-0000-1000-8000-00805F9B34FB';
  static const frequencyCharacteristicUuid = '0000FA13-0000-1000-8000-00805F9B34FB';
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

  Stream<List<int>> get packets => _packets.stream;
  int get frequencyHz => _frequencyHz;

  void setFrequency(int value) {
    if (!const {5, 10, 20}.contains(value)) {
      throw ArgumentError.value(value, 'value', 'BLE frequency must be 5, 10, or 20 Hz');
    }
    _frequencyHz = value;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ value), (_) {
      final telemetry = _latest;
      if (telemetry != null) _packets.add(utf8.encode(jsonEncode(telemetry.toJson())));
    });
  }

  void publish(LiveTelemetry telemetry) => _latest = telemetry;
  Future<void> dispose() async {
    _timer?.cancel();
    await _packets.close();
  }
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
  StreamSubscription<List<int>>? _telemetrySubscription;
  StreamSubscription<List<int>>? _commandSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _controllerPacketSubscription;
  BluetoothDevice? _controller;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _frequencyCharacteristic;
  bool _isDisposed = false;
  bool _controllerGattStarted = false;
  final Map<String, BytesBuilder> _commandBuffers = {};

  Stream<LiveTelemetry> get telemetry => _telemetry.stream;
  Stream<ControllerCommand> get commands => _commands.stream;
  Stream<bool> get connectionState => _connection.stream;
  DeviceRole get role => DeviceRoleStorage.fromStorage(_prefs.getString(_roleKey));
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
    if (_controllerGattStarted) return;
    await peripheral.BlePeripheral.initialize();
    await peripheral.BlePeripheral.clearServices();
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
    peripheral.BlePeripheral.setWriteRequestCallback(_onGattWrite);
    _controllerPacketSubscription = publisher.packets.listen((packet) {
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
    _commandBuffers.clear();
  }

  Future<void> setFrequency(int frequencyHz) async {
    publisher.setFrequency(frequencyHz);
    await _prefs.setInt(_frequencyKey, frequencyHz);
    final characteristic = _frequencyCharacteristic;
    if (characteristic != null) {
      await characteristic.write(utf8.encode('$frequencyHz'), withoutResponse: false);
    }
  }

  Stream<List<ScanResult>> scanForControllers() async* {
    await FlutterBluePlus.startScan(
      withServices: [Guid(RallyBleGatt.serviceUuid)],
      timeout: const Duration(seconds: 8),
    );
    yield* FlutterBluePlus.scanResults;
  }

  Stream<List<BleControllerDevice>> scanForControllerDevices() {
    return scanForControllers().map((results) => results.map((result) {
      return BleControllerDevice(
        id: result.device.remoteId.str,
        name: result.device.platformName.isEmpty
            ? 'Rally Controller'
            : result.device.platformName,
        rssi: result.rssi,
      );
    }).toList(growable: false));
  }

  Future<void> pair(BluetoothDevice controller) async {
    await _connect(controller);
    await _prefs.setString(_pairedControllerKey, controller.remoteId.str);
  }

  Future<void> pairControllerId(String id) =>
      pair(BluetoothDevice(remoteId: DeviceIdentifier(id)));

  Future<void> reconnect() async {
    final id = pairedControllerId;
    if (id == null || id.isEmpty) return;
    await _connect(BluetoothDevice(remoteId: DeviceIdentifier(id)));
  }

  Future<void> _connect(BluetoothDevice controller) async {
    await disconnect();
    await stopControllerAdvertising();
    _controller = controller;
    await controller.connect(autoConnect: false);
    _connectionSubscription = controller.connectionState.listen((state) {
      final connected = state == BluetoothConnectionState.connected;
      _connection.add(connected);
      if (!connected && !_isDisposed && role != DeviceRole.controller) {
        Future<void>.delayed(const Duration(seconds: 2), reconnect);
      }
    });
    final services = await controller.discoverServices();
    final service = services.firstWhere(
      (candidate) => candidate.uuid == Guid(RallyBleGatt.serviceUuid),
    );
    final telemetryCharacteristic = service.characteristics.firstWhere(
      (candidate) => candidate.uuid == Guid(RallyBleGatt.telemetryCharacteristicUuid),
    );
    _commandCharacteristic = service.characteristics.firstWhere(
      (candidate) => candidate.uuid == Guid(RallyBleGatt.commandCharacteristicUuid),
    );
    final frequencyCharacteristics = service.characteristics.where(
      (candidate) => candidate.uuid == Guid(RallyBleGatt.frequencyCharacteristicUuid),
    );
    _frequencyCharacteristic = frequencyCharacteristics.isEmpty
        ? null
        : frequencyCharacteristics.first;
    await telemetryCharacteristic.setNotifyValue(true);
    _telemetrySubscription = telemetryCharacteristic.lastValueStream.listen((bytes) {
      if (bytes.isEmpty) return;
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _telemetry.add(LiveTelemetry.fromJson(map));
    });
  }

  Future<void> sendCommand(ControllerCommand command) async {
    final characteristic = _commandCharacteristic;
    if (characteristic == null) throw StateError('No Controller command characteristic is connected');
    await characteristic.write(utf8.encode(jsonEncode(command.toJson())), withoutResponse: false);
  }

  Future<void> disconnect() async {
    await _telemetrySubscription?.cancel();
    await _commandSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _telemetrySubscription = null;
    _commandSubscription = null;
    _connectionSubscription = null;
    final controller = _controller;
    _controller = null;
    _commandCharacteristic = null;
    _frequencyCharacteristic = null;
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
  }
}
