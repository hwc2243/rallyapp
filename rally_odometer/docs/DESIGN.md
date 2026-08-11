# Design Specification: Rally Odometer

## Visual Hierarchy & Typography
- **Orientation:** Locked to Landscape Mode.
- **Typography:** True Monospace font ('Courier' or 'Roboto Mono') for all numerical, mileage, heading, and time displays to prevent character-width jitter.
- **Contrast:** High-contrast only. No gradients or shadows.
- **Layout:** Split screen horizontally (50/50).
  - **Top Row:** Total Odometer (Left/Center), Current Time (Top-Right).
  - **Bottom Row:** Interval Odometer (Left/Center), Current Time (Top-Right).

## Header & Navigation Menu
- **Top Bar Controls:** Located in the top header area.
- **Menu Button:** A high-contrast overflow button (`⋮` or `MENU`) replacing the single settings gear.
- **Menu Items (Modal Popover):**
  1. **Settings:** Navigates to Settings modal/page.
  2. **Details:** Opens the Live GPS Details diagnostic dialog.

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

## Speedometer Integration
- **Placement:** Slim horizontal bar centered between Top and Bottom rows.
- **Visuals:** Centered text `SPD: [Value] [Units]`.
- **Status Indicator:** Speed text glows **Green** when Speed-Sense filter is "ACTIVE" and **Dim Grey** when "STATIONARY".

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