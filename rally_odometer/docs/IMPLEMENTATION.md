# Implementation Plan: Rally Odometer

## Technical Stack
- **State Management:** Riverpod (for 20Hz high-frequency updates).
- **Location Engine:** `geolocator` package with `LocationAccuracy.high`.
- **Logic:** Haversine formula for "Ground Truth" calculations; Linear Interpolation for real-time display.
- **Persistence:** `shared_preferences` for settings and state recovery.

## Timing & Precision
- **Logic & UI Refresh:** The system must run a `Timer.periodic` at **20Hz (every 50ms)**.
- **Visuals:** Mileage must increment in real-time between GPS pulses to provide a smooth, high-resolution display (the thousandths digit should appear to "roll").
- **Clock Resolution:** - Seconds Mode: Display `HH:mm:ss`.
    - Decimal Mode: Display `HH:mm.[hundredths]`.
    - Formula: `(Seconds * 5) / 3`, updated at 10Hz minimum to prevent skipping digits.

## Unified Distance Accumulation & Interpolation Pipeline
The system operates on two concurrent loops: the **Interpolation Engine** (The "Pulser") and the **GPS Correction Loop**.

### 1. High-Frequency Interpolation (The "Pulser")
Runs at **20Hz (50ms)** to ensure the thousandths digit updates smoothly and provides an immediate response to "Reset" or "Hold" actions.
- **Speed Smoothing:** `current_speed` is a weighted average of the last 3 valid GPS samples.
- **Tick Calculation:**
    - `incremental_distance = current_speed * 0.05` (Speed in m/s * 50ms).
    - `AppliedDelta = incremental_distance * calibration_factor * dir_mult`.
- **Accumulation:** `total_distance += AppliedDelta`; `interval_distance += AppliedDelta`.

### 2. GPS Correction Loop ("Ground Truth")
Validates raw data and "anchors" the dead-reckoning interpolation to physical reality.
1. **The Accuracy Gate:**
    - Reject any sample where `position.accuracy > 15m`.
    - If `DateTime.now().difference(last_timestamp) > 5s`, perform a **Hard Reset** of the anchor (ignore the "leap" distance to prevent background jumps).
2. **The Stationary Lock (Hysteresis):**
    - Lock at `< 0.8 m/s` for 3s. Unlock at `> 1.2 m/s`.
    - While `isLocked`, force `current_speed = 0.0` in the Pulser loop.
3. **True Park Integrity:**
    - If `dir_mult == 0.0` (PARK):
        - Discard all distance deltas.
        - **Critical:** Continuously update `last_position = current_position` during Park. This ensures that when shifting back to Forward/Reverse, the app doesn't "leap" the distance traveled while the car was in Park.
4. **Soft Sync (Drift Correction):**
    - Periodically compare cumulative GPS distance vs. Interpolated distance.
    - If variance $> 2$ meters, subtly snap the Odometer to the GPS value to correct long-term dead-reckoning drift.

## Data Schema & Persistence
| Key | Type | Default | Trigger |
| :--- | :--- | :--- | :--- |
| `is_metric` | bool | `false` | On Toggle |
| `is_decimal_minutes` | bool | `false` | On Toggle |
| `calibration_factor` | double | `1.000` | On Change/Entry |
| `bump_amount` | double | `0.010` | On Change |
| `bump_require_double_tap` | bool | `false` | On Toggle |
| `total_distance` | double | `0.0` | Every 5s or App Pause |
| `interval_distance` | double | `0.0` | Every 5s or App Pause |

## Feature Logic

### Bump Logic
- `total_distance = total_distance + (bump_amount_in_meters)`
- Note: If `dir_mult == -1.0`, the bump logic remains additive (it is a manual correction of the current display value, not a movement delta).

### Hold State Logic
- **Variables:** `isHeld` (bool), `frozenMileage` (double), `frozenTime` (DateTime).
- **Logic:**
    - `if (isHeld)`: Freeze `displayMileage` and `displayTime` at the moment of tap. 
    - **Background:** The **Pulser** and **GPS Loops** must continue to update `actualMileage` and `systemTime` in the background.
    - `if (release)`: Snap `display` values to `actual` background values immediately.

### Interaction Logic
- Use `GestureDetector` to wrap Bump buttons.
- If `bump_require_double_tap == true`, ignore `onTap` and only execute on `onDoubleTap`.

---

### Final Implementation Checklist for Developer:
- [ ] Install `wakelock_plus`, `geolocator`, `shared_preferences`, and `flutter_riverpod`.
- [ ] Configure `Info.plist` (iOS) and `AndroidManifest.xml` (Android) for **Always** background location permissions.
- [ ] Implement the `Timer.periodic(Duration(milliseconds: 50))` inside the `OdometerNotifier`.
- [ ] Add the "Satellite Dish" icon to the header, color-coded by the Accuracy Gate status (Green <10m, Yellow 10-15m, Red >15m).
