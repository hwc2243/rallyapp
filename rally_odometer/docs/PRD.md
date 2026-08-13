# Product Requirement Document: Rally Odometer (`rally_odometer`)

## Application Overview
A high-precision, user-facing Flutter application for TSD Rallying powered by `rally_lib`[cite: 12, 13].

## UI Core Specifications
1. **Target Platforms:** iOS and Android[cite: 12, 13].
2. **Viewport:** Forced landscape orientation[cite: 12, 13].
3. **Display Resolution:** Numerical mileage displays rendered to thousandths precision (0.000) and Numerical speed displays rendered to whole number (no decimal point)[cite: 12, 13].
4. **Placement & Icon:** Hamburger menu icon (`≡`) situated in the **bottom-right** corner of the screen[cite: 12, 13].
- **Menu Items:**
  1. **Settings:** Opens application configuration screen[cite: 12, 13].
  2. **Details:** Opens full-screen diagnostic view[cite: 12, 13].
- **Full-Screen Details Screen Requirements:**
  - Full-page route with dedicated return/back navigation[cite: 12, 13].
  - Displays real-time streaming telemetry from `rally_lib`: Latitude, Longitude, Speed, Bearing (Degrees + Cardinal direction), and Color-Coded GPS Accuracy (Green <10m, Yellow 10–15m, Red >15m)[cite: 12, 13].
  - Viewing the Details screen must not pause background tracking or telemetry updates[cite: 12, 13].

## Multi-Device UI Modes
The application supports three operational modes selected via Settings[cite: 13, 14]:

### 1. Controller Mode (Default Master)
- Standard full-featured UI including Total/Interval rows, Hold/Release, Resets, Bumps, FPR controls, and Settings/Details menu[cite: 13, 14].
- Requires hardware GPS[cite: 13, 14].
- **Primary Dashboard Layout:**
   - **Top Row:** Total Odometer mileage, system clock (HH:mm:ss)[cite: 12, 13].
   - **Bottom Row:** Trip/Interval Odometer mileage, system clock (HH:mm:ss)[cite: 12, 13].

### 2. Driver Display Mode
- **Screen Layout:** Simplified, high-contrast display showing:
  - Total Mileage
  - Interval Mileage
  - Vehicle Speed
  - GPS Accuracy Indicator
- **Excluded UI Elements:** All control buttons (Reset, Hold, Bumps, FPR) are hidden/omitted[cite: 13, 14].
- **Navigation & Menu:** Bottom-right hamburger menu contains **ONLY** the **Details** option[cite: 13, 14].
- **Display Behavior:** Total mileage continuously increments live, regardless of whether Controller or Navigator is in a "Held" state.

### 3. Navigator Display Mode
- **Screen Layout:** Clones the Controller UI layout (Total/Interval, Speed, Resets, Bumps, Hold, FPR, Settings/Details)[cite: 13, 14].
- **Interaction Logic:** Tapping any control button sends a `ControllerCommand` packet over BLE to the Controller rather than mutating local state directly.
- **Hold Syncing:** Tapping Hold or Release updates both Navigator and Controller screens simultaneously.

## Odometer Controls & Interactivity
- **Reset Buttons:** Dedicated "Reset" buttons located to the right of Total and Interval displays[cite: 12, 13].
- **Hold / Release Feature:**
  - Top row "Hold" button freezes the displayed Total mileage and time[cite: 12, 13].
  - Background tracking continues uninterrupted via `rally_lib`[cite: 12, 13].
  - Tapping "Release" jumps display values to current live background values immediately[cite: 12, 13].
- **Direct Mileage Entry:** Tapping mileage displays opens a numeric keypad modal (0.000 precision) for manual value override[cite: 12, 13].
- **Mileage Bump Controls:**
  - "Bump+" and "Bump-" buttons to quickly adjust Total mileage[cite: 12, 13].
  - Configurable "Single-Tap" vs "Double-Tap" safety mode setting[cite: 12, 13].
- **FPR Direction Toggle:** 3-state vertical segmented control (Forward, Park, Reverse)[cite: 12, 13].

## Calibration & Numerical Entry Dialogs
- **Clear Button Requirement:** Every manual input dialog (Direct Mileage Entry, Official Distance Entry, Calibration Factor Entry) must include a dedicated **"CLEAR"** button[cite: 12, 13].
- **Behavior:** Tapping "CLEAR" immediately clears active text fields to allow quick re-entry[cite: 12, 13].

## Factor Calculation & Confirmation UX
- **Calculated Factor Preview Modal:** When calculating factor via "Official Distance", the UI must present a preview modal showing `Current Factor` alongside `New Factor`[cite: 12, 13].
- **User Confirmation:** The new factor must not be applied to `rally_lib` until the user explicitly taps "CONFIRM" or "APPLY"[cite: 12, 13].

## Visual Guidance & Status Overlays
- **Startup Calibration Overlay:** Displays a "Calibrating..." pop-up overlay while `rally_lib` is in Calibration Mode[cite: 12, 13].
- **Bearing Guidance UI:**
  - Displays "N/A" when bearing is uninitialized[cite: 12, 13].
  - Displays helper message: *"Data will be available when motion is detected."* when bearing is unavailable[cite: 12, 13].

## Viewport Safety & Render Continuity
- **Overflow Immunity:** All UI views (Dashboard, Settings, Details) must dynamically adapt to landscape mobile viewports without `RenderFlex` overflow errors[cite: 12, 13].
- **Scroll Support:** Secondary screens must support vertical scrolling if content exceeds viewport boundaries[cite: 12, 13].
- **Frame Continuity:** 20Hz display refresh must remain smooth without freezing or jumping[cite: 12, 13].
