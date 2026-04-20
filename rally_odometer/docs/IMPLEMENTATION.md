# Implementation Plan

## Technical Stack
- **State Management:** Riverpod (for high-frequency odometer updates).
- **Location Engine:** `geolocator` package with `LocationAccuracy.high`.
- **Logic:** Haversine formula for distance calculation between GPS coordinates to ensure precision.
- **Flavors:** Use Flutter Flavors to manage "Free" vs "Pro" versions.

## Timing & Precision
- **Clock Resolution:** To prevent "skipping" when displaying hundredths of a minute (decimal minutes), the UI must update at a minimum frequency of **10Hz (every 100ms)**.
- **Conversion Logic:**
    * Seconds Mode: Display `HH:mm:ss`.
    * Decimal Mode: Display `HH:mm.[hundredths]`.
    * Formula for Hundredths: `(Seconds / 60) * 100` or simply `(Seconds * 5) / 3`, rounded to the nearest whole number.
- **Synchronization:** The display logic must pull from the system clock (`DateTime.now()`) on every tick rather than incrementing a local counter to prevent drift.

## Speed-Sense Noise Filtering
- **Operational States:**
  1. **STATIONARY (Speed < 0.8 m/s):** Strictly ignore all GPS coordinate changes. Do not accumulate mileage.
  2. **TRANSITION (Speed 0.8 m/s to 2.5 m/s):** Apply a "Minimum Movement" threshold of 1.5 meters per update to filter out signal drift.
  3. **ACTIVE (Speed > 2.5 m/s):** Zero filtering. Accumulate all reported distance changes to ensure maximum precision during rally segments.
- **Accuracy Guard:** Regardless of speed, ignore any GPS fix with a horizontal accuracy > 15 meters.

## Data Schema
- `total_distance`: double (meters)
- `interval_distance`: double (meters)
- `is_metric`: boolean
- `is_decimal_minutes`: boolean
- `calibration_factor`: double (Default: 1.00000)
- `official_mileage_input`: double (Temporary storage for calculation)

### Calculation Logic
- `Calculated_Distance = Raw_GPS_Distance * calibration_factor`
- The factor should be persisted locally (e.g., using `shared_preferences`).

### Hold State Logic
- **State Variables:** - `isHeld`: boolean
    - `frozenMileage`: double
    - `frozenTime`: DateTime
- **Logic:**
    - `if (!isHeld)`: 
        - `displayMileage = actualMileage`
        - `displayTime = DateTime.now()`
    - `if (isHeld)`:
        - `displayMileage` remains at the value captured at the moment `isHeld` became true.
        - `displayTime` remains at the value captured at the moment `isHeld` became true.
