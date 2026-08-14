# Product Requirement Document: Rally Odometer (`rally_odometer`)

## Application Overview
A high-precision, user-facing Flutter application for TSD Rallying powered by `rally_lib`[cite: 6, 7].

## UI Core Specifications
1. **Target Platforms:** iOS and Android[cite: 7].
2. **Viewport:** Forced landscape orientation[cite: 7].
3. **Display Precision Standards:**
   - **Numerical Mileage Displays:** Rendered to thousandths precision (`0.000`)[cite: 7].
   - **Vehicle Speed Displays:** Rendered strictly as a **whole integer with zero decimal places** (e.g., `45 MPH` using `.round()`) across all screens and views[cite: 7].
4. **Global Rally Time Sync:**
   - Settings must support entering an official rally time to calculate a persistent duration offset (`timeDelta = enteredRallyTime - deviceTime`)[cite: 10].
   - All app clocks (`NavigatorDashboardScreen`, `DriverDashboardScreen`, `DetailsScreen`) must render `deviceTime + timeDelta` in `HH:mm:ss` format[cite: 10, 11].
5. **Wakelock Integration:** The application must keep the device screen awake indefinitely (`WakelockPlus.enable()`) while active, preventing lock screen timeouts or dimming.
6. **Header & Overflow Navigation Menu:**
    1. **`Details`**: Opens full-screen diagnostic view.
    2. **View Toggle Action**: Contextually displays **`Navigator View`** (when in Driver View) or **`Driver View`** (when in Navigator View).
    3. **`Settings`**: Opens application configuration screen.

- **Full-Screen Details Screen Requirements:**
  - Full-page route with dedicated return/back navigation[cite: 7].
  - Displays real-time streaming telemetry from `rally_lib`: Latitude, Longitude, Speed (whole number), Bearing (Degrees + Cardinal direction), and Color-Coded GPS Accuracy (Green <10m, Yellow 10–15m, Red >15m)[cite: 6, 7].
  - Viewing the Details screen must not pause background tracking or telemetry updates[cite: 7].

## Multi-Device UI Modes
The application supports three operational modes selected via Settings[cite: 7]:

### 1. Controller Mode (Default Master)
- Requires hardware GPS[cite: 7].
- **Display View Selector:** When operating in `Controller` mode, Settings shall provide an option to toggle the local UI view: `[ Driver View | Navigator View ]`[cite: 6, 7].
- **Behavior:**
  - **`Driver View`:** Renders the high-visibility 2x2 grid `DriverDashboardScreen` layout on the Controller device[cite: 6, 7].
  - **`Navigator View` (Default):** Renders the full control dashboard layout on the Controller device[cite: 7].
- **Engine Continuity:** Toggling between views affects **UI rendering only**. The underlying Controller services (hardware GPS engine, distance calculation, background tracking, and BLE GATT server broadcasting) remain 100% active at all times regardless of the active view[cite: 7].

### 2. Driver Display Mode
- **Layout Architecture:** Does not use a top `AppBar` to ensure maximum vertical clearance in landscape mode.
- **Top Header Area:** Contains the **Colored Satellite Dish Icon** (reflecting live GPS accuracy gate) on the left[cite: 6].
- **Screen Layout (2x2 Quadrant Grid):**
  - **Top-Left:** Total Mileage (High-viz Green, `0.000` precision)[cite: 6].
  - **Top-Right:** Vehicle Speed (Whole number integer, e.g., `45 MPH`)[cite: 6, 7].
  - **Bottom-Left:** Interval Mileage (High-viz Yellow, `0.000` precision)[cite: 6].
  - **Bottom-Right:** Current System Time (`HH:mm:ss` format)[cite: 6].
- **Excluded UI Elements:** All control buttons (Reset, Hold, Bumps, FPR) are omitted[cite: 7].
- **Navigation & Contextual Overflow Menu:** Positioned in the **bottom-left** corner[cite: 6].
  - **Standalone Driver Mode (`isControllerEngine == false`):** Overflow menu contains **`Details`** option ONLY[cite: 6, 7].
  - **Controller Engine Driver Mode (`isControllerEngine == true`):** Overflow menu contains both **`Settings`** and **`Details`** options so the user can navigate back to Settings to switch display views.
- **Display Behavior:** Total mileage continuously increments live, regardless of whether Controller or Navigator is in a "Held" state[cite: 7].
- **Menu Placement:** Floating in bottom-right corner with grid padding to prevent text overlap.

### 3. Navigator Display Mode
- **Screen Layout:**
   - **Top Row:** Total Odometer mileage, system clock (`HH:mm:ss`)[cite: 6, 7].
   - **Bottom Row:** Trip/Interval Odometer mileage, system clock (`HH:mm:ss`)[cite: 6, 7].
- **Interaction Logic:** Tapping any control button sends a `ControllerCommand` packet over BLE to the Controller rather than mutating local state directly[cite: 7].
- **Hold Syncing:** Tapping Hold or Release updates both Navigator and Controller screens simultaneously[cite: 7].

## Odometer Controls & Interactivity
- **Reset Buttons:** Dedicated "Reset" buttons located to the right of Total and Interval displays[cite: 6, 7].
- **Hold / Release Feature:**
  - Top row "Hold" button freezes the displayed Total mileage and time[cite: 6, 7].
  - Background tracking continues uninterrupted via `rally_lib`[cite: 7].
  - Tapping "Release" jumps display values to current live background values immediately[cite: 7].
- **Direct Mileage Entry:** Tapping mileage displays opens a numeric keypad modal (0.000 precision) for manual value override[cite: 6, 7].
- **Mileage Bump Controls:**
  - "Bump+" and "Bump-" buttons to quickly adjust Total mileage[cite: 6, 7].
  - Configurable "Single-Tap" vs "Double-Tap" safety mode setting[cite: 6, 7].
- **FPR Direction Toggle:** 3-state vertical segmented control (Forward, Park, Reverse)[cite: 6, 7].

## Calibration & Numerical Entry Dialogs
- **Clear Button Requirement:** Every manual input dialog (Direct Mileage Entry, Official Distance Entry, Calibration Factor Entry) must include a dedicated **"CLEAR"** button[cite: 6, 7].
- **Behavior:** Tapping "CLEAR" immediately clears active text fields to allow quick re-entry[cite: 6, 7].

## Factor Calculation & Confirmation UX
- **Calculated Factor Preview Modal:** When calculating factor via "Official Distance", the UI must present a preview modal showing `Current Factor` alongside `New Factor`[cite: 6, 7].
- **User Confirmation:** The new factor must not be applied to `rally_lib` until the user explicitly taps "CONFIRM" or "APPLY"[cite: 7].

## Visual Guidance & Status Overlays
- **Startup Calibration Overlay:** Displays a "Calibrating..." pop-up overlay while `rally_lib` is in Calibration Mode[cite: 6, 7].
- **Bearing Guidance UI:**
  - Displays "N/A" when bearing is uninitialized[cite: 6, 7].
  - Displays helper message: *"Data will be available when motion is detected."* when bearing is unavailable[cite: 6, 7].

## Viewport Safety & Render Continuity
- **Overflow Immunity:** All UI views (Dashboard, Settings, Details) must dynamically adapt to landscape mobile viewports without `RenderFlex` overflow errors[cite: 6, 7].
- **Scroll Support:** Secondary screens must support vertical scrolling if content exceeds viewport boundaries[cite: 6, 7].
- **Frame Continuity:** 20Hz display refresh must remain smooth without freezing or jumping[cite: 6, 7].