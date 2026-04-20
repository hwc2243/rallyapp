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

## Unified Distance Accumulation Pipeline
All incoming GPS `Position` objects must pass through this sequence:

1. **The Accuracy Gate:** - If `position.accuracy > 15m`, discard the sample.
   - If `DateTime.now().difference(last_timestamp) > 5s`, discard the first sample (Resync).

2. **The Stationary Lock (Hysteresis):**
   - If `current_speed < 0.8 m/s` for 3 consecutive seconds: Set `isLocked = true`.
   - If `isLocked == true` AND `current_speed < 1.2 m/s`: Force `speed_multiplier = 0.0` and discard distance.
   - If `current_speed > 1.2 m/s`: Set `isLocked = false`.

3. **The Speed-Sense Sieve:**
   - **TRANSITION (Speed 1.2 to 2.5 m/s):** Only accumulate distance if `delta_distance > 1.5 meters`.
   - **ACTIVE (Speed > 2.5 m/s):** Accumulate all `delta_distance`.

4. **The final Calculation:**
   - `FinalDelta = DeltaDistance * calibration_factor * dir_mult`
   - `TotalOdometer += FinalDelta`

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

## Directional Math Logic
- **Multiplier variable (`dir_mult`):**
  - If State == Forward: `dir_mult = 1.0`
  - If State == Park: `dir_mult = 0.0`
  - If State == Reverse: `dir_mult = -1.0`
- **Formula:** `new_distance = current_distance + (delta_gps * calibration_factor * dir_mult)`

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
