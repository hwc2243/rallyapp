# Design Specification: Rally Odometer

## Visual Hierarchy & Typography
- **Orientation:** Locked to Landscape Mode[cite: 6, 7].
- **Typography:** True Monospace font ('Courier' or 'Roboto Mono') for all numerical, mileage, heading, and time displays to prevent character-width jitter[cite: 6].
- **Contrast:** High-contrast only. Pure black background (`#000000`)[cite: 6]. No gradients or shadows[cite: 6].
- **Wakelock:** Screen brightness kept awake indefinitely via `wakelock_plus`.

## Device Role Configuration Screen
- **Role Selector:** 3-way segmented button or radio card list: `[ Controller | Driver | Navigator ]`[cite: 6].
- **Controller Display View Selector:** Visible when Role is set to `Controller`: `[ Driver View | Navigator View ]`[cite: 6].
- **BLE Rate Selector (Controller Mode):** Segmented choice: `[ 5 Hz | 10 Hz (Default) | 20 Hz ]`[cite: 6].
- **Device Pairing Wizard:** Clean scanning list showing discovered Controller BLE devices with signal strength indicators (RSSI)[cite: 6].

## Driver Display Layout (2x2 Grid)
- **Orientation:** Forced Landscape Mode[cite: 6].
- **AppBar Avoidance:** Does **not** use `AppBar` to ensure maximum vertical space utilization.
- **Visuals:** Pure Black background (`#000000`), High-viz Green for Total, High-viz Yellow for Interval, Crisp White for Speed and Clock[cite: 6].
- **Header Overlay Area:** Centered GPS Satellite Dish Icon, color-coded by accuracy (<10m Green, 10–15m Yellow, >15m Red).
- **Body Layout (2x2 Quadrant Grid):**
  - **Top-Left Quad:** Total Mileage (Large monospace, High-viz Green)[cite: 6].
  - **Top-Right Quad:** Vehicle Speed (Large monospace, Whole Number, e.g., `45 MPH`)[cite: 6, 7].
  - **Bottom-Left Quad:** Interval Mileage (Large monospace, High-viz Yellow)[cite: 6].
  - **Bottom-Right Quad:** Current System Time (`HH:mm:ss` format)[cite: 6].
- **Menu Placement:** Positioned in the **bottom-right** corner of the screen layout[cite: 6].

## Connection Error Modal
- **Visual Style:** High-contrast alert window[cite: 6].
- **Title:** "Controller Connection Failed"[cite: 6]
- **Message:** "Unable to connect to saved Controller display over Bluetooth."[cite: 6]
- **Action Buttons:**
  - **RETRY:** High-viz Green button[cite: 6].
  - **RECONFIGURE ROLE:** High-viz Yellow/Amber button[cite: 6].

## Calibration Overlay
- **Visuals:** A floating, semi-transparent badge anchored near the top-center of the main screen with high-contrast text: **"Calibrating..."**[cite: 6].
- **Behavior:** Appears automatically on startup; fades out smoothly once GPS signal stabilizes and Calibration Mode exits[cite: 6].

## Header & Navigation Menu
- **GPS Status Icon:** Satellite dish icon displayed in top header area, color-coded based on GPS accuracy gate (Green <10m, Yellow 10–15m, Red >15m)[cite: 6].
- **Overflow Menu Icon:** High-contrast standard **Hamburger Icon** (`Icons.menu` / three horizontal lines) positioned in the **bottom-left** corner[cite: 6].
- **Behavior:** Tapping hamburger icon displays modal popover with options:
  1. **`Details`**
  2. **View Toggle Action** (`Driver View` / `Navigator View`)
  3. **`Settings`** **Details** (Live GPS diagnostics: Lat/Lon, Speed, Bearing, Color-Coded Accuracy)[cite: 6].

## Live Details Diagnostic Screen
- **Content Display:**
  - **Latitude / Longitude:** e.g., `LAT: 37.7749° N` | `LON: -122.4194° W`[cite: 6]
  - **Speed:** e.g., `SPD: 45 MPH` (Whole integer)[cite: 6, 7]
  - **Bearing / Heading:** e.g., `HDG: 184° (S)`[cite: 6]
  - **GPS Accuracy Indicator:** Badge display showing accuracy in meters (e.g., `ACC: ± 4.2m`)[cite: 6].
    - **Color Coding:** 
      - **Green:** < 10m (High Precision)[cite: 6]
      - **Yellow:** 10m – 15m (Moderate)[cite: 6]
      - **Red:** > 15m (Low Precision / Filtering Active)[cite: 6]

## Telemetry & Bearing UI (Details & Main Screen)
- **Bearing Display:**
  - Active: Displays formatted degrees and cardinal direction (e.g., `HDG: 184° S`)[cite: 6].
  - Uninitialized: Displays `HDG: N/A` (never `0°`)[cite: 6].
- **Motion Helper Message:**
  - Positioned directly beneath or adjacent to the bearing readout on the **Details Screen**[cite: 6].
  - Text: *"Data will be available when motion is detected"* (styled in dim grey/amber when bearing is `N/A`, hidden once valid heading is locked)[cite: 6].

## Low-Speed Rendering
- Mileage updates at low speed (e.g., walking speed) must increment smoothly without numerical flicker, horizontal layout shifting, or regression[cite: 6].

## Button Layout & Interaction (Navigator View)
- **Control Column:** Far right column (~15% screen width)[cite: 6].
  - Top Row: [HOLD/RELEASE] stacked above [RESET][cite: 6].
  - Bottom Row: [RESET][cite: 6].
- **Bump Controls:** Two square buttons (`+` / `-`) on Top Row between mileage and control column. Optional `x2` badge if Double-Tap safety is enabled[cite: 6].
- **FPR Control:** Vertical segmented toggle (Forward = Green, Park = Dim White/Grey, Reverse = Bold Red)[cite: 6].

## Wakelock & Performance
- **Wakelock:** Screen stays at 100% brightness indefinitely while active[cite: 6].
- **Frame Rate:** Mileage and telemetry update at 20fps for smooth numerical rolling[cite: 6].

## Direct Mileage & Calibration Entry Dialogs
- **Activation:** Tapping numerical displays or calibration input fields[cite: 6].
- **Interface:** High-contrast modal pop-up with a numeric keypad (0–9 and decimal point)[cite: 6].
- **Button Layout & Styling:**
  - **SET:** Large, high-visibility Green button[cite: 6].
  - **CANCEL:** Large, high-visibility Red button[cite: 6].
  - **CLEAR (CLR):** Distinct Amber/Yellow or high-contrast button positioned adjacent to input field to allow immediate single-tap clearing[cite: 6].

## Calibration Factor Confirmation Modal
- **Activation:** Triggered immediately after submitting a value in the "Official Distance" calculation input[cite: 6].
- **Visual Layout:**
  - **Header:** High-contrast title "Confirm New Calibration Factor"[cite: 6].
  - **Comparison Display:**
    - `Current Factor:` e.g., `1.0000`[cite: 6]
    - `New Factor:` e.g., `1.0048` (Large, high-contrast text)[cite: 6]
  - **Action Buttons:**
    - **CONFIRM / APPLY:** Large, high-visibility Green button[cite: 6].
    - **CANCEL:** Large, high-visibility Red button[cite: 6].

## Responsive Layout & Safety Standards
- **SafeArea Integration:** All full-screen routes (`DetailsScreen`, `SettingsScreen`) must be wrapped in a `SafeArea` to prevent system notches or gestures from obscuring content[cite: 6].
- **Details Screen Responsiveness:** On smaller display targets, the telemetry body must utilize a scrollable container (`SingleChildScrollView`) or adaptive grid sizing to prevent clipping[cite: 6].