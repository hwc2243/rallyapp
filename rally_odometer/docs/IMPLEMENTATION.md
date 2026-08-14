# Implementation Plan: Rally Odometer App (`rally_odometer`)

## Technical Stack & Dependencies
- **UI Framework:** Flutter (Forced landscape orientation)[cite: 10, 12].
- **Service Integration:** Local path dependency `rally_lib` (`package:rally_lib/rally_lib.dart`)[cite: 10, 12].
- **State Subscription:** `flutter_riverpod` listening to live telemetry streams provided by `rally_lib`[cite: 10, 12].
- **Screen Wakelock:** `wakelock_plus` plugin to prevent device sleep or auto-lock during active usage[cite: 10, 12].

## Screen Wakelock Integration
- **Requirement:** Prevent screen dimming, sleep, or lock screen timeout across all screens and device roles[cite: 10, 12].
- **Initialization:** Invoke `WakelockPlus.enable()` on application startup[cite: 10, 12].

## Rally Time Offset & Clock Synchronization

### 1. Requirements & Core Concept
- **Problem:** Official rally scoring clocks often differ slightly from standard device system time.
- **Solution:** Allow the user to input the current official rally time in Settings. The application calculates the difference between the entered rally time and device time as a time offset duration (`timeDelta`) and stores it globally[cite: 10].
- **Global Display Application:** All time displays throughout the app (`NavigatorDashboardScreen`, `DriverDashboardScreen`, `DetailsScreen`, etc.) must render `deviceTime + timeDelta` instead of raw device time[cite: 10, 11, 12].

### 2. Settings Integration (`SettingsScreen`)
- **Control Entry:** Add a **"Sync Rally Clock"** setting option in `SettingsScreen`.
- **Input Workflow:** Tapping opens a time entry modal/dialog pre-populated with current device time or previous offset time (`HH:mm:ss`).
- **Calculation:** Upon confirmation, calculate:
  $$\text{timeDelta} = \text{enteredRallyTime} - \text{currentDeviceTime}$$
- **State Persistence:** Store `timeDelta` (in seconds or as a `Duration`) in a persistent Riverpod provider (e.g., `rallyTimeOffsetProvider`) and persist to local preferences.
- **Reset Option:** Provide a "Reset Time Offset" button to clear `timeDelta` back to zero (exact device time).

### 3. Global Time Provider
- **Provider Logic:** Centralize system clock rendering inside `currentTimeProvider`.
- **Computation:** Whenever `currentTimeProvider` emits a time tick, it evaluates `DateTime.now().add(timeDelta)` and formats it as `HH:mm:ss`.
- **Automatic Propagation:** Because all views watch `currentTimeProvider`, updating `timeDelta` instantly shifts all visible clocks across the application without altering screen structure or widget hierarchies[cite: 10].

## UI Navigation & Settings Menu

### 1. Settings Icon & Menu Access
- **Icon Standard:** Both Driver View and Navigator View must use a high-contrast **Gear Icon** (`Icons.settings`) for the bottom-right settings button[cite: 10, 11].
- **Menu Structure (Controller Mode - `isControllerEngine == true`):**
  1. **`Details`**: Opens full-screen diagnostic route[cite: 10, 12].
  2. **View Toggle Action**: 
     - Displays **`Driver View`** option when currently rendering Navigator View[cite: 10, 12].
     - Displays **`Navigator View`** option when currently rendering Driver View[cite: 10, 12].
     - Tapping toggles `controllerDisplayViewProvider` state immediately[cite: 10].
  3. **`Settings`**: Opens application configuration screen[cite: 10, 12].
- **Menu Structure (Standalone Device - `isControllerEngine == false`):**
  - Displays **`Details`** option ONLY[cite: 10, 12].

### 2. Full-Screen Details View (`DetailsScreen`)
- **Route Architecture:** Full-page route pushed onto Navigator stack with dedicated back navigation[cite: 10, 12].
- **State Integration:** Subscribes to live telemetry to present Latitude, Longitude, Bearing (Degrees + Cardinal direction), Speed (whole number integer), and GPS Accuracy[cite: 10, 11, 12].
- **Accuracy Color Scheme:** Green (< 10m), Yellow (10m–15m), Red (> 15m)[cite: 10, 11, 12].

## Controller Display View Switching & Engine Isolation

### Local View State
- **Setting Key:** `controller_display_view` (`'driver'` | `'navigator'`, default: `'navigator'`)[cite: 10, 12].
- **State Management:** Riverpod `controllerDisplayViewProvider` manages local active view[cite: 10].

### Engine Isolation Rule
- **UI-Only Scope:** Switching between Driver View and Navigator View on a Controller device swaps the active visual screen widget tree only[cite: 10, 12].
- **Service Continuity:** Changing views must never pause, reset, or restart background GPS tracking, distance calculations, or BLE broadcasts[cite: 10, 12].

## Driver Display & 2x2 Grid Layout (`DriverDashboardScreen`)

### Visual Specs
- **Viewport:** Full landscape screen without top `AppBar` to avoid vertical clipping[cite: 10, 11, 12].
- **Header:** GPS Satellite Dish icon horizontally centered at top, color-coded by signal accuracy[cite: 10, 11, 12].
- **2x2 Grid Layout:**
  - **Top-Left:** Total Mileage (High-viz Green, `0.000` precision)[cite: 10, 11, 12].
  - **Top-Right:** Vehicle Speed (Whole integer, e.g., `45 MPH`)[cite: 10, 11, 12].
  - **Bottom-Left:** Interval Mileage (High-viz Yellow, `0.000` precision)[cite: 10, 11, 12].
  - **Bottom-Right:** Current System Time (`HH:mm:ss` format, adjusted by `timeDelta`)[cite: 10, 11, 12].
- **Settings Trigger:** Positioned in the bottom-right corner as a floating overlay using the **Gear Icon** (`Icons.settings`)[cite: 10, 11].
- **Live Update Guarantee:** The Driver View total mileage and clock always stream real-time updates and are never frozen by Navigator Hold actions[cite: 10, 12].

## Navigator Display & Control Layout (`NavigatorDashboardScreen`)

The Navigator view splits into a **Telemetry Display Area (Left ~75%)** and a **Control Column Area (Right ~25%)**[cite: 10, 11].

### 1. Left Telemetry Area (~75% Screen Width)

#### Top Section (Total Odometer Block)
- **Top Header Bar:**
  - **Centered Clock:** Green system time (`HH:mm:ss`, adjusted by `timeDelta`) centered at the top of the Total section[cite: 10].
- **Main Display Row:**
  - **Inline Label & Mileage:** The bold green `TOTAL (mi)` label is positioned directly inline to the left of the large green Total mileage text (`0.000` precision)[cite: 10].
  - **Bump Controls & Satellite Layout (Right Side):**
    - Stacked `BUMP+` and `BUMP-` buttons positioned on the far right of the Total section[cite: 10, 11].
    - **Satellite Dish Icon:** Positioned directly to the left of the bump buttons column (above bump area), color-coded by accuracy[cite: 10].

#### Middle Section (Speed Divider Bar)
- **Speed Bar:** Centered monospace readout `SPEED: X MPH` (whole integer), bounded above and below by horizontal divider lines[cite: 10].

#### Bottom Section (Interval Odometer Block)
- **Top Header Bar:**
  - **Centered Clock:** Yellow system time (`HH:mm:ss`, adjusted by `timeDelta`) centered at the top of the Interval section[cite: 10].
- **Main Display Row:**
  - **Inline Label & Mileage:** The bold yellow `INTERVAL (mi)` label is positioned directly inline to the left of the large yellow Interval mileage text (`0.000` precision)[cite: 10].

### 2. Right Control Area (~25% Screen Width)
Split vertically into two sub-columns[cite: 10, 11]:

- **Sub-Column 1 (FPR Direction Control):**
  - Vertical stack containing `FORWARD` (Green active fill), `PARK` (Dark grey fill), and `REVERSE` (Dark grey fill)[cite: 10, 11].
- **Sub-Column 2 (Action Controls):**
  - **Top Group (Total Section Controls):** `HOLD` button on top, Total `RESET` button immediately below it[cite: 10, 11].
  - **Horizontal Divider Line:** A crisp horizontal dividing line visually separating the top Total controls (`HOLD` & Top `RESET`) from the bottom controls[cite: 10].
  - **Bottom Group (Interval & App Controls):** Interval `RESET` button below the divider, and the Settings **Gear Button** (`Icons.settings`) at the very bottom right[cite: 10].

## Hold Behavior & State Persistence Rules

### 1. Persistent State Requirement
- **Global Lifecycle:** The `HOLD` state (including `isHeld`, frozen Total distance value, and frozen timestamp) must be stored in a persistent Riverpod provider (`navigatorHoldProvider`)[cite: 10].
- **View Swap Resilience:** Toggling from Navigator View to Driver View (or navigating away to Details or Settings) must **NOT** reset, release, or clear the active Hold state[cite: 10].
- **Restoration on Return:** When returning to `NavigatorDashboardScreen`, read from `navigatorHoldProvider`. If `isHeld == true`, display the held total distance and held timestamp until `RELEASE` is tapped[cite: 10].

### 2. View Isolation Rule
- **Navigator Scope Only:** The `HOLD` feature strictly affects the rendering of Total distance and clock on the **Navigator View**[cite: 10, 12].
- **Driver View Streaming:** The **Driver View** must always subscribe directly to real-time live telemetry (`totalDistance` and system clock) regardless of whether Navigator View is in a Held state[cite: 10, 12].

## Global Formatting & System Rules

### Speed Readout Standard
- All speed readouts across all screens (`DriverDashboardScreen`, `NavigatorDashboardScreen`, `DetailsScreen`) must format values as whole numbers with zero decimals using `.round()`[cite: 10, 12].

### Calibration Factor Confirmation Workflow
1. User submits value in "Official Distance" field[cite: 10, 11, 12].
2. App presents modal displaying `Current Factor` alongside `Calculated New Factor` preview[cite: 10, 11, 12].
3. Factor updates in `rally_lib` only upon explicit user tap of "CONFIRM" or "APPLY"[cite: 10, 11, 12].

### Entry Dialog Handling
- All manual entry dialogs (Mileage override, Official distance, Calibration factor, Time offset entry) must include a dedicated **"CLEAR"** button that clears active text input without closing the modal[cite: 10, 11, 12].

### Viewport Safety
- Secondary screens (`DetailsScreen`, `SettingsScreen`) wrapped in `SafeArea` and `SingleChildScrollView` to prevent `RenderFlex` overflow errors on landscape mobile viewports[cite: 10, 11, 12].