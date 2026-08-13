# Implementation Plan: Rally Odometer App (`rally_odometer`)

## Technical Stack & Dependencies
- **UI Framework:** Flutter (Forced landscape orientation)[cite: 6, 7].
- **Service Integration:** Local path dependency `rally_lib` (`package:rally_lib/rally_lib.dart`).
- **State Subscription:** `flutter_riverpod` listening to live telemetry streams provided by `rally_lib`[cite: 7].
- **Screen Wakelock:** `wakelock_plus` plugin to prevent device sleep or auto-lock during active usage[cite: 6, 7].

## Screen Wakelock Integration
- **Requirement:** Prevent screen dimming, sleep, or lock screen timeout across all screens and device roles[cite: 6, 7].
- **Initialization:** Invoke `WakelockPlus.enable()` on application startup[cite: 7].

## UI Navigation & Settings Menu

### 1. Settings Icon & Menu Access
- **Icon Standard:** Both Driver View and Navigator View must use a high-contrast **Gear Icon** (`Icons.settings`) for the bottom-right settings button[cite: 6].
- **Menu Structure (Controller Mode - `isControllerEngine == true`):**
  1. **`Details`**: Opens full-screen diagnostic route[cite: 6, 7].
  2. **View Toggle Action**: 
     - Displays **`Driver View`** option when currently rendering Navigator View[cite: 6, 7].
     - Displays **`Navigator View`** option when currently rendering Driver View[cite: 6, 7].
     - Tapping toggles `controllerDisplayViewProvider` state immediately[cite: 7].
  3. **`Settings`**: Opens application configuration screen[cite: 6, 7].
- **Menu Structure (Standalone Device - `isControllerEngine == false`):**
  - Displays **`Details`** option ONLY[cite: 6, 7].

### 2. Full-Screen Details View (`DetailsScreen`)
- **Route Architecture:** Full-page route pushed onto Navigator stack with dedicated back navigation[cite: 7].
- **State Integration:** Subscribes to live telemetry to present Latitude, Longitude, Bearing (Degrees + Cardinal direction), Speed (whole number integer), and GPS Accuracy[cite: 6, 7].
- **Accuracy Color Scheme:** Green (< 10m), Yellow (10m–15m), Red (> 15m)[cite: 6, 7].

## Controller Display View Switching & Engine Isolation

### Local View State
- **Setting Key:** `controller_display_view` (`'driver'` | `'navigator'`, default: `'navigator'`)[cite: 6, 7].
- **State Management:** Riverpod `controllerDisplayViewProvider` manages local active view[cite: 7].

### Engine Isolation Rule
- **UI-Only Scope:** Switching between Driver View and Navigator View on a Controller device swaps the active visual screen widget tree only[cite: 7].
- **Service Continuity:** Changing views must never pause, reset, or restart background GPS tracking, distance calculations, or BLE broadcasts[cite: 7].

## Driver Display & 2x2 Grid Layout (`DriverDashboardScreen`)

### Visual Specs
- **Viewport:** Full landscape screen without top `AppBar` to avoid vertical clipping[cite: 6, 7].
- **Header:** GPS Satellite Dish icon horizontally centered at top, color-coded by signal accuracy[cite: 6, 7].
- **2x2 Grid Layout:**
  - **Top-Left:** Total Mileage (High-viz Green, `0.000` precision)[cite: 6].
  - **Top-Right:** Vehicle Speed (Whole integer, e.g., `45 MPH`)[cite: 6, 7].
  - **Bottom-Left:** Interval Mileage (High-viz Yellow, `0.000` precision)[cite: 6].
  - **Bottom-Right:** Current System Time (`HH:mm:ss` format)[cite: 6].
- **Settings Trigger:** Positioned in the bottom-right corner as a floating overlay using the **Gear Icon** (`Icons.settings`)[cite: 6].
- **Live Update Guarantee:** The Driver View total mileage and clock always stream real-time updates and are never frozen by Navigator Hold actions[cite: 7].

## Navigator Display & Control Layout (`NavigatorDashboardScreen`)

The Navigator view splits into a **Telemetry Display Area (Left ~75%)** and a **Control Column Area (Right ~25%)**[cite: 6].

### 1. Left Telemetry Area (~75% Screen Width)

#### Top Section (Total Odometer Block)
- **Top Header Bar:**
  - **Centered Clock:** Green system time (`HH:mm:ss`) centered at the top of the Total section[cite: 6].
- **Main Display Row:**
  - **Inline Label & Mileage:** The bold green `TOTAL (mi)` label is positioned directly inline to the left of the large green Total mileage text (`0.000` precision)[cite: 6].
  - **Bump Controls & Satellite Layout (Right Side):**
    - Stacked `BUMP+` and `BUMP-` buttons positioned on the far right of the Total section[cite: 6].
    - **Satellite Dish Icon:** Positioned directly to the left of the bump buttons column (above bump area), color-coded by accuracy[cite: 6].

#### Middle Section (Speed Divider Bar)
- **Speed Bar:** Centered monospace readout `SPEED: X MPH` (whole integer), bounded above and below by horizontal divider lines[cite: 6, 7].

#### Bottom Section (Interval Odometer Block)
- **Top Header Bar:**
  - **Centered Clock:** Yellow system time (`HH:mm:ss`) centered at the top of the Interval section[cite: 6].
- **Main Display Row:**
  - **Inline Label & Mileage:** The bold yellow `INTERVAL (mi)` label is positioned directly inline to the left of the large yellow Interval mileage text (`0.000` precision)[cite: 6].

### 2. Right Control Area (~25% Screen Width)
Split vertically into two sub-columns[cite: 6]:

- **Sub-Column 1 (FPR Direction Control):**
  - Vertical stack containing `FORWARD` (Green active fill), `PARK` (Dark grey fill), and `REVERSE` (Dark grey fill)[cite: 6].
- **Sub-Column 2 (Action Controls):**
  - **Top Group (Total Section Controls):** `HOLD` button on top, Total `RESET` button immediately below it[cite: 6].
  - **Horizontal Divider Line:** A crisp horizontal dividing line visually separating the top Total controls (`HOLD` & Top `RESET`) from the bottom controls.
  - **Bottom Group (Interval & App Controls):** Interval `RESET` button below the divider, and the Settings **Gear Button** (`Icons.settings`) at the very bottom right[cite: 6].

## Hold Behavior & State Persistence Rules

### 1. Persistent State Requirement
- **Global Lifecycle:** The `HOLD` state (including the `isHeld` boolean flag, frozen Total distance value, and frozen timestamp) must be stored in a persistent Riverpod provider (e.g., `navigatorHoldProvider`) rather than transient widget state (`StatefulWidget` or local `State`).
- **View Swap Resilience:** Toggling from Navigator View to Driver View (or navigating away to Details or Settings) must **NOT** reset, release, or clear the active Hold state[cite: 7].
- **Restoration on Return:** When returning to `NavigatorDashboardScreen`, the screen must read from the persistent Hold provider. If `isHeld == true`, it must display the held total distance and held timestamp until the user explicitly taps `RELEASE`[cite: 7].

### 2. View Isolation Rule
- **Navigator Scope Only:** The `HOLD` feature strictly affects the rendering of the Total distance and clock on the **Navigator View**[cite: 7].
- **Driver View Streaming:** The **Driver View** must always subscribe directly to real-time live telemetry (`totalDistance` and system clock) regardless of whether the Navigator View is currently in a Held state[cite: 7].

## Global Formatting & System Rules

### Speed Readout Standard
- All speed readouts across all screens (`DriverDashboardScreen`, `NavigatorDashboardScreen`, `DetailsScreen`) must format values as whole numbers with zero decimals using `.round()`[cite: 6, 7].

### Calibration Factor Confirmation Workflow
1. User submits value in "Official Distance" field[cite: 6].
2. App presents modal displaying `Current Factor` alongside `Calculated New Factor` preview[cite: 6].
3. Factor updates in `rally_lib` only upon explicit user tap of "CONFIRM" or "APPLY"[cite: 6, 7].

### Entry Dialog Handling
- All manual entry dialogs (Mileage override, Official distance, Calibration factor) must include a dedicated **"CLEAR"** button that clears active text input without closing modal[cite: 6, 7].

### Viewport Safety
- Secondary screens (`DetailsScreen`, `SettingsScreen`) wrapped in `SafeArea` and `SingleChildScrollView` to prevent `RenderFlex` overflow errors on landscape mobile viewports[cite: 6, 7].