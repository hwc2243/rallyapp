# Implementation Plan: Rally Lib (`rally_lib`)

## Technical Stack & Dependencies
- **State Management:** Riverpod (`flutter_riverpod` for 20Hz telemetry & high-frequency updates).
- **Location Engine:** `geolocator` package configured for background updates and high accuracy.
- **Background Engine:** `flutter_background_service` with native OS permissions (`UIBackgroundModes` location on iOS, `ACCESS_BACKGROUND_LOCATION` on Android)[cite: 14, 15].
- **Persistence:** `shared_preferences` key-value store[cite: 14, 15].
- **BLE Central Engine (Driver / Navigator):** `flutter_blue_plus` for scanning, connecting, and subscribing to GATT notifications[cite: 14, 15].
- **BLE Peripheral Engine (Controller):** `ble_peripheral` for full GATT server hosting, service creation, characteristic notification broadcasts, and write request listeners.

## Telemetry Data Schema
```dart
class LiveTelemetry {
  final double totalDistance;
  final double intervalDistance;
  final DateTime timestamp;
  final double speed;        // in m/s or user units
  final double? bearing;     // 0.0 - 360.0 degrees (null if uninitialized)
  final double latitude;
  final double longitude;
  final double gpsAccuracy;  // in meters
  final bool isDisplayHeld;  // Synchronizes hold state across connected BLE devices

  LiveTelemetry({
    required this.totalDistance,
    required this.intervalDistance,
    required this.timestamp,
    required this.speed,
    required this.bearing,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
    required this.isDisplayHeld,
  });

  Map<String, dynamic> toJson();
  factory LiveTelemetry.fromJson(Map<String, dynamic> json);
}

## Controller GATT Server Implementation (`ble_peripheral`)
1. **Service Initialization:**
   - Define `BleService` with UUID `0000FA10-0000-1000-8000-00805F9B34FB`.
   - **Telemetry Characteristic (`Notify`):**
     - UUID: `0000FA11-0000-1000-8000-00805F9B34FB`
     - Properties: `[notify, read]`
   - **Command Characteristic (`Write`):**
     - UUID: `0000FA12-0000-1000-8000-00805F9B34FB`
     - Properties: `[write, writeWithoutResponse]`
2. **Execution Flow:**
   - **Advertising:** Start advertising with service UUID `0000FA10-0000-1000-8000-00805F9B34FB` and device name `RallyController`.
   - **Telemetry Dispatch:** Periodically call `BlePeripheral.updateCharacteristic()` with serialized `LiveTelemetry` JSON/CBOR bytes at the selected frequency (5Hz / 10Hz / 20Hz).
   - **Command Reception:** Set `BlePeripheral.setWriteRequestCallback()` to intercept incoming `ControllerCommand` payloads, deserialize them, and trigger local `OdometerNotifier` actions.