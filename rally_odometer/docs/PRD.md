# Product Requirement Document: Rally Odometer

## Project Overview
A high-precision GPS-based odometer designed specifically for TSD (Time Speed Distance) Rallying.

## Core Requirements
1. **Platform:** iOS and Android (Flutter).
2. **Display:** Forced landscape mode.
3. **Accuracy:** Distance must be tracked to the **thousandths** (0.000).
4. **Dual Odometer Logic:**
   - **Total Odometer:** Cumulative distance since start/reset.
   - **Trip/Interval Odometer:** Distance since last manual split/instruction.
5. **GPS Support:** Use internal mobile GPS by default; support external NMEA GPS sources if connected via Bluetooth/Serial.

### Odometer Controls
- **Reset Functionality:** Each odometer (Total and Interval) must have a dedicated "Reset" button located to the right of the numerical display.
    - Action: Tapping "Reset" sets the corresponding distance to 0.000.
- **Total Odometer "Hold" Feature:**
    - The Total Odometer row includes a "Hold" button.
    - **Function:** When tapped, the "Hold" button must freeze **both** the mileage display and the time display for the Top Row.
    - **Background Behavior:** - The master odometer must continue to accumulate mileage.
      - The master system clock must continue to track real-time.
    - **Release Behavior:** When "Release" is tapped, both the mileage and the time must jump to the current real-time values.
    - **Toggle State:**
        - While frozen, the button text changes to **"Release"**.
        - Tapping "Release" updates the display immediately to the current accumulated background mileage and master system clock and reverts the button text to **"Hold"**.
- **Direct Mileage Entry Feature:**
    - **Function:** Allows the user to manually override the current odometer value with a specific number.
    - **Scope:** Must be available for both the Total and Interval odometers independently.
    - **Input:** A numeric keypad pop-up (supporting 0.000 precision).
    - **State preservation:** Manually entering a value does **not** reset the calibration factor; it simply offsets the current distance counter.
- **Mileage Bump Feature:**
    - **Function:** Provides two quick-action buttons ("Bump+" and "Bump-") to the Total Odometer.
    - **Logic:** Tapping "Bump+" adds the preset amount to the Total mileage; "Bump-" subtracts it.
    - **Configuration:** The increment value (e.g., 0.010 or 0.005) must be user-configurable in the Settings.
    - **Persistence:** The chosen bump amount must be saved to local storage.
    - **Bump Interaction Safety:**
      - **Feature:** A configuration setting to toggle between "Single-Tap" and "Double-Tap" for Bump buttons.
      - **Default:** Single-Tap.
      - **Logic:** If "Double-Tap to Bump" is enabled, the odometer will only increment/decrement if two taps are detected within 300ms.

### Odometer Direction Control (FPR)
- **Control Type:** A 3-state toggle or segmented control (Forward, Park, Reverse).
- **Default State:** Forward.
- **States & Logic:**
  1. **Forward (F):** Mileage accumulates normally (Added to totals).
  2. **Park (P):** Mileage accumulation is strictly disabled, regardless of GPS movement.
  3. **Reverse (R):** Distance traveled is **subtracted** from both the Total and Interval odometers.
- **UI Placement:** Located to the immediate left of the control buttons (Reset/Hold) on the right side of the screen.

## Feature Specifications
- **Main UI:** Two primary rows. Top row = Total Odometer. Bottom row = Interval Odometer.
- **Clock:** Both rows must display the current system time (HH:mm:ss).
- **Settings:**
  - Unit Toggle: Miles vs. Kilometers.
  - Time Format: Seconds vs. Hundredths of a minute (Decimal minutes).
- ** GPS Accuracy:**
  - Display a GPS signal indicator. Green = <10m, Yellow = 10-15m, Red = >15m (Filtering Active).

### Calibration & Factor
- **Calibration Factor:** A multiplier applied to the raw GPS distance to align with official rally mileage.
- **Input Methods:**
  1. **Direct Entry:** User manually types a numerical factor (e.g., 1.0050).
  2. **Calculated Entry:** User enters the "Official/Measured Mileage" (e.g., 10.000) and the app calculates the factor by comparing it against the current "App Odometer Mileage." 
     * Formula: `Factor = Official Mileage / App Odometer Mileage`

### Odometer Precision Logic
- The application must intelligently pause mileage accumulation when the vehicle is detected as stationary to prevent "GPS Wander."
- **Visual Feedback (Optional):** When the Speed-Sense filter is actively suppressing noise, the mileage display could subtly change (e.g., a small "Pause" icon or the text turning slightly grey) so the navigator knows the odometer is "parked."

### Precision & Park Logic
- **Park Integrity:** When the state is "PARK," the app must strictly ignore all distance deltas. Upon switching back to "Forward" or "Reverse," the system must not "catch up" on any distance covered while in Park.
- **Update Frequency:** The numerical display must provide the illusion of constant movement (mimicking a physical gear-driven pulser).
- **Odometer "Tick" Resolution:** Mileage must increment in real-time between GPS pulses to provide a smooth, high-resolution display.

## Data Persistence
- **Calibration Factor:** must be saved anytime it is changed and should persist across app restarts, device reboots, and updates. On app launch the odometer should default to the last saved calibration

- **Versioning:** - Free Version: "Rally Odometer" (Basic tracking).
  - Paid Version: "Rally Odometer Pro" (Additional rally-specific features).

