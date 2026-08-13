/// A Controller discovered by the BLE scanning wizard.
class BleControllerDevice {
  final String id;
  final String name;
  final int rssi;

  const BleControllerDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
}
