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

### Odometer Precision & Noise Filtering
- **Stationary Suppression:** When vehicle speed drops below 0.8 m/s (~1.8 mph) for 3 consecutive seconds, the app must enter a locked stationary state and force all distance deltas to `0.0`.
- **Monotonicity Guard (Prevent Distance Loss):** 
  - While in **Forward** mode, total and interval mileage must be **strictly non-decreasing** (`delta >= 0.0`).
  - GPS resynchronization or drift corrections must **never** reduce the accumulated distance counter. If a soft sync detects that raw GPS distance is behind interpolated distance, forward accumulation pauses until physical position catches up, but the display never jumps backward.
  - Decrements to distance are strictly forbidden unless the FPR state is explicitly set to **Reverse**.

### Startup Calibration Mode
- **Initial Stabilization:** Upon app launch or GPS service re-initialization, the system must enter an automatic **Calibration Mode**.
- **Distance Suppression:** While in Calibration Mode, all distance accumulation is strictly locked (`delta = 0.0`) to prevent startup positional drift from falsifying mileage.
- **UI Overlay:** A small, high-contrast overlay pop-up displaying **"Calibrating..."** must be shown.
- **Exit Condition:** Calibration Mode automatically completes once the GPS receiver achieves an accuracy of `< 15m` and positional readings remain within a stable cluster across 3 consecutive readings.

### Low-Speed Precision & Windowed Tracking
- **Low-Speed Accrual:** Distance must accurately accumulate at slow speeds (e.g., walking/crawling speeds between 0.3 m/s and 1.2 m/s). Slow movement must not be entirely discarded as stationary noise.
- **Multi-Sample Windowing:** At low speeds, distance calculation must use multi-sample time-window averaging across sequential coordinates to filter out GPS jitter while accurately capturing net displacement.
- **Monotonic Smoothing:** Low-speed accumulation must strictly satisfy non-decreasing constraints (`delta >= 0.0` in Forward mode) and must never jump backward or fluctuate erratically.

### Bearing Persistence & State
- **Bearing Retention:** Once a valid bearing/heading is calculated, it must be **retained continuously** until a new valid bearing is established. It must never drop to `0°` when stopping or crawling.
- **Empty State Display:** If no bearing has been determined yet (e.g., cold start before motion), the bearing value must explicitly display as **"N/A"** (never `0°`).
- **User Motion Guidance:** When bearing is unavailable ("N/A"), the UI must present an explanatory message stating: *"Data will be available when motion is detected."*

### Menu & Navigation Controls
- **Overflow Menu:** The main interface replaces a standalone settings button with a primary **Menu** button (overflow icon).
- **Placement & Icon:** The main navigation menu must be located in the **bottom-right** corner of the interface and represented by a standard **hamburger icon** (`≡`).
- **Menu Options:**
  1. **Operation:** Tapping the hamburger icon opens a popover menu containing **Settings** and **Details**.
  2. **Settings:** Opens configuration options (Unit toggle, Decimal minutes toggle, Bump settings, Double-tap safety, Calibration Factor).
  3. **Details:** Navigates to the full **Details Screen** (utilizes the same full-screen page navigation paradigm as Settings).
- **Details Screen Requirements:**
  - Full-page view with a clear return/back action to return to the main dashboard.
  - Continuously streams live telemetry updates in real-time:
    - Latitude & Longitude
    - Current Speed
    - Bearing (Degrees + Cardinal direction)
    - Color-Coded GPS Accuracy (Green <10m, Yellow 10-15m, Red >15m)
  - Opening or viewing the Details screen must **not** pause background odometer accumulation or telemetry tracking.

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


### Device Layout & Viewport Safety
- **Overflow Immunity:** All UI screens (including main dashboard, Settings, and Details) must dynamically adapt to constrained landscape viewports (e.g., iPhones with notches and home indicator bars) without layout overflows or `RenderFlex` errors.
- **Scroll Grace Period:** Any full-screen view whose content exceeds the physical vertical screen height must automatically enable smooth vertical scrolling.
