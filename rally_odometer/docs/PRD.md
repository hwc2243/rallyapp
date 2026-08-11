# Product Requirement Document: Rally Odometer

## Project Overview
A high-precision GPS-based odometer designed specifically for TSD (Time Speed Distance) Rallying.

## Core Requirements
1. **Platform:** iOS and Android (Flutter).
2. **Display:** Forced landscape mode.
3. **Accuracy:** Distance must be tracked to the **thousandths** (0.000).
4. **Background Operation:** The app must continuously track GPS position, calculate mileage, and update internal state in the background when minimized or when the screen is locked.
5. **Dual Odometer Logic:**
   - **Total Odometer:** Cumulative distance since start/reset.
   - **Trip/Interval Odometer:** Distance since last manual split/instruction.
6. **GPS & Telemetry:** 
   - Use internal mobile GPS by default; support external NMEA GPS sources if connected via Bluetooth/Serial.
   - Capture real-time vehicle **Bearing/Heading** (0°–360°).

### Live Telemetry Data Structure
The app must maintain a continuous, real-time data structure containing:
- `total_odometer` (double)
- `interval_odometer` (double)
- `timestamp` (DateTime)
- `speed` (double)
- `bearing` (double, degrees 0-360)
- `latitude` (double)
- `longitude` (double)
- `gps_accuracy` (double, meters)

**Continuous Update Rule:** Telemetry parameters (`timestamp`, `speed`, `bearing`, `latitude`, `longitude`, `gps_accuracy`) must update continuously at the master refresh rate, **even if the odometer accumulation is paused or set to PARK.**

### Menu & Navigation Controls
- **Overflow Menu:** The main interface replaces a standalone settings button with a primary **Menu** button (overflow icon).
- **Menu Options:**
  1. **Settings:** Opens configuration options (Unit toggle, Decimal minutes toggle, Bump settings, Double-tap safety, Calibration Factor).
  2. **Details:** Opens a dedicated live diagnostic view displaying:
     - Current Latitude & Longitude
     - Current Speed
     - Current Bearing (Heading in degrees + compass cardinal direction)
     - GPS Accuracy (Color-coded: Green = <10m, Yellow = 10-15m, Red = >15m)

### Odometer Controls
- **Reset Functionality:** Each odometer (Total and Interval) has a dedicated "Reset" button located to the right of the numerical display.
    - Action: Tapping "Reset" sets the corresponding distance to 0.000.
- **Total Odometer "Hold" Feature:**
    - Freezes display of mileage and time for the top row while master accumulation continues in the background.
    - Tapping "Release" jumps display values to real-time master values immediately.
- **Direct Mileage Entry Feature:**
    - Manual override popup for Total or Interval odometer values (0.000 precision). Does not reset calibration factor.
- **Mileage Bump Feature:**
    - "Bump+" and "Bump-" buttons to adjust Total mileage by a configured increment.
    - Configurable "Single-Tap" vs "Double-Tap" safety mode in Settings.

### Odometer Direction Control (FPR)
- **Control Type:** 3-state toggle (Forward, Park, Reverse).
  1. **Forward (F):** Mileage accumulates normally.
  2. **Park (P):** Mileage accumulation is strictly disabled. Movement during Park is ignored upon returning to F/R.
  3. **Reverse (R):** Mileage is subtracted from totals.

### Calibration & Factor
- **Input Methods:** Direct numeric entry or Calculated entry (`Factor = Official Mileage / App Odometer Mileage`).
- **Data Persistence:** Calibration factor, bump amount, unit preferences, and odometer states must persist across app restarts and reboots.
