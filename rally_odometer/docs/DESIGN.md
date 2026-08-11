# Design Specification: Rally Odometer

## Visual Hierarchy & Typography
- **Orientation:** Locked to Landscape Mode.
- **Typography:** True Monospace font ('Courier' or 'Roboto Mono') for all numerical, mileage, heading, and time displays to prevent character-width jitter.
- **Contrast:** High-contrast only. No gradients or shadows.
- **Layout:** Split screen horizontally (50/50).
  - **Top Row:** Total Odometer (Left/Center), Current Time (Top-Right).
  - **Bottom Row:** Interval Odometer (Left/Center), Current Time (Top-Right).

## Calibration Overlay
- **Visuals:** A floating, semi-transparent badge anchored near the top-center of the main screen with high-contrast text: **"Calibrating..."**.
- **Behavior:** Appears automatically on startup; fades out smoothly once GPS signal stabilizes and Calibration Mode exits.

## Header & Navigation Menu
- **Top Bar Controls:** Located in the top header area.
- **Menu Placement:** Positioned in the **bottom-right** corner of the screen.
- **Iconography:** Uses a high-contrast standard **Hamburger Icon** (`Icons.menu` / three horizontal lines).
- **Behavior:** Tapping the hamburger icon displays a modal popover with options:
  1. **Settings**
  2. **Details** (Live GPS diagnostics: Lat/Lon, Speed, Bearing, Color-Coded Accuracy)

## Live Details Diagnostic Modal
- **Style:** High-contrast pop-up window over the main UI.
- **Content Display:**
  - **Latitude / Longitude:** e.g., `LAT: 37.7749° N` | `LON: -122.4194° W`
  - **Speed:** e.g., `SPD: 45.2 MPH`
  - **Bearing / Heading:** e.g., `HDG: 184° (S)`
  - **GPS Accuracy Indicator:** Badge display showing accuracy in meters (e.g., `ACC: ± 4.2m`).
    - **Color Coding:** 
      - **Green:** < 10m (High Precision)
      - **Yellow:** 10m – 15m (Moderate)
      - **Red:** > 15m (Low Precision / Filtering Active)

## Telemetry & Bearing UI (Details & Main Screen)
- **Bearing Display:**
  - Active: Displays formatted degrees and cardinal direction (e.g., `HDG: 184° S`).
  - Uninitialized: Displays `HDG: N/A` (never `0°`).
- **Motion Helper Message:**
  - Positioned directly beneath or adjacent to the bearing readout on the **Details Screen**.
  - Text: *"Data will be available when motion is detected"* (styled in dim grey/amber when bearing is `N/A`, hidden once valid heading is locked).

## Speedometer Integration
- **Placement:** Slim horizontal bar centered between Top and Bottom rows.
- **Visuals:** Centered text `SPD: [Value] [Units]`.
- **Status Indicator:** Speed text glows **Green** when Speed-Sense filter is "ACTIVE" and **Dim Grey** when "STATIONARY".

## Low-Speed Rendering
- Mileage updates at low speed (e.g., walking speed) must increment smoothly without numerical flicker, horizontal layout shifting, or regression.

## Button Layout & Interaction
- **Control Column:** Far right column (~15% screen width).
  - Top Row: [HOLD/RELEASE] stacked above [RESET].
  - Bottom Row: [RESET].
- **Bump Controls:** Two square buttons (`+` / `-`) on Top Row between mileage and control column. Optional `x2` badge if Double-Tap safety is enabled.
- **FPR Control:** Vertical segmented toggle (Forward = Green, Park = Dim White/Grey, Reverse = Bold Red).

## GPS Status Icon
- **Visual:** Satellite dish icon displayed in top header. Color-coded based on GPS accuracy gate (Green <10m, Yellow 10-15m, Red >15m).

## Wakelock & Performance
- **Wakelock:** Screen stays at 100% brightness indefinitely while active.
- **Frame Rate:** Mileage and telemetry update at 20fps for smooth numerical rolling.

## Visual Performance, Display Continuity, & Safety Guards
- **Monotonic Display Rule:** In Forward mode, odometer numbers must strictly increment or remain frozen. They must never flicker downward or jump backward during GPS soft-syncing.
- **20Hz UI Ticker Isolation:** The numerical display refresh (20fps) must run on an isolated UI ticker loop. 
- **Anti-Stutter Rule:** The display must never pause or "batch update" (freeze and jump ahead). Even if GPS updates arrive intermittently, the UI ticker must smoothly interpolate the display using the last known speed vector until new ground-truth data arrives.
- **Zero-Movement Pinning:** When Stationary Lock is active, the thousandths digit must remain completely static (no flickering or micro-increments).

## Navigation & Screen Routes
- **Details Screen:** Designed as a dedicated full-screen view sharing the same visual frame, header layout, and back-button navigation behavior as the Settings screen.
- **Details Screen Layout:**
  - **Header:** Full-width top bar containing screen title ("LIVE DETAILS") and a high-contrast Back/Close button.
  - **Body Grid:** Clean, high-contrast full-screen telemetry grid:
    - **Coordinates:** Large monospace text for `LAT` and `LON`.
    - **Speed & Heading:** Prominent displays for `SPD` and `HDG` (e.g., `HDG: 184° S`).
    - **GPS Accuracy Badge:** Prominently styled accuracy display with dynamic color fills:
      - **Green:** `< 10m`
      - **Yellow:** `10m – 15m`
      - **Red:** `> 15m`

## Direct Mileage & Calibration Entry Dialogs
- **Activation:** Tapping numerical displays or calibration input fields.
- **Interface:** High-contrast modal pop-up with a numeric keypad (0–9 and decimal point).
- **Button Layout & Styling:**
  - **SET:** Large, high-visibility Green button.
  - **CANCEL:** Large, high-visibility Red button.
  - **CLEAR (CLR):** Distinct Amber/Yellow or high-contrast button positioned adjacent to the keypad input field to allow immediate single-tap clearing.

## Calibration Factor Confirmation Modal
- **Activation:** Triggered immediately after submitting a value in the "Official Distance" calculation input.
- **Visual Layout:**
  - **Header:** High-contrast title "Confirm New Calibration Factor".
  - **Comparison Display:** Prominently displays the values side-by-side or stacked:
    - `Current Factor:` e.g., `1.0000`
    - `New Factor:` e.g., `1.0048` (Large, high-contrast text).
  - **Action Buttons:**
    - **CONFIRM / APPLY:** Large, high-visibility Green button to commit the new factor.
    - **CANCEL:** Large, high-visibility Red button to discard the calculation and retain the current factor.

## Responsive Layout & Safety Standards
- **SafeArea Integration:** All full-screen routes (`DetailsScreen`, `SettingsScreen`) must be wrapped in a `SafeArea` to prevent system notches or gestures from obscuring content or crowding layout boundaries.
- **Details Screen Responsiveness:**
  - On smaller display targets (e.g., iPhone landscape mode), the telemetry body must utilize a scrollable container (`SingleChildScrollView`) or adaptive grid sizing.
  - Text, badges, and diagnostic tiles must dynamically scale or reflow rather than clipping or pushing past bottom screen bounds.
