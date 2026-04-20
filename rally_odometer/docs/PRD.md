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

## Feature Specifications
- **Main UI:** Two primary rows. Top row = Total Odometer. Bottom row = Interval Odometer.
- **Clock:** Both rows must display the current system time (HH:mm:ss).
- **Settings:**
  - Unit Toggle: Miles vs. Kilometers.
  - Time Format: Seconds vs. Hundredths of a minute (Decimal minutes).

### Calibration & Factor
- **Calibration Factor:** A multiplier applied to the raw GPS distance to align with official rally mileage.
- **Input Methods:**
  1. **Direct Entry:** User manually types a numerical factor (e.g., 1.0050).
  2. **Calculated Entry:** User enters the "Official/Measured Mileage" (e.g., 10.000) and the app calculates the factor by comparing it against the current "App Odometer Mileage." 
     * Formula: `Factor = Official Mileage / App Odometer Mileage`

### Odometer Precision Logic
- The application must intelligently pause mileage accumulation when the vehicle is detected as stationary to prevent "GPS Wander."
- **Visual Feedback (Optional):** When the Speed-Sense filter is actively suppressing noise, the mileage display could subtly change (e.g., a small "Pause" icon or the text turning slightly grey) so the navigator knows the odometer is "parked."

- **Versioning:** - Free Version: "Rally Odometer" (Basic tracking).
  - Paid Version: "Rally Odometer Pro" (Additional rally-specific features).
