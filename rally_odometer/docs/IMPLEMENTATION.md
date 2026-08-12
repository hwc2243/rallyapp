# Implementation Plan: Rally Odometer App (`rally_odometer`)

## Technical Stack & Dependencies
- **UI Framework:** Flutter (Forced landscape layout)[cite: 14].
- **Service Integration:** Local path dependency `rally_lib` (`package:rally_lib/rally_lib.dart`).
- **State Subscription:** `flutter_riverpod` listening to live telemetry streams provided by `rally_lib`[cite: 14].

## UI Navigation & Routes

### 1. Main Overflow Menu (Bottom-Right)
- Implement `PopupMenuButton` using `Icon(Icons.menu)` positioned in the bottom-right corner of the layout (within the control stack)[cite: 14].
- Options: `Settings` and `Details`[cite: 14].

### 2. Full-Screen Details View (`DetailsScreen`)
- **Route Architecture:** Pushed onto the Navigator stack as a full-page route matching `SettingsScreen`[cite: 14].
- **Live State Subscription:** Consumes `LiveTelemetry` Riverpod provider to dynamically update coordinates, speed, bearing, and accuracy[cite: 14].
- **Color Formatting Helper:**
  ```dart
  Color getAccuracyColor(double accuracy) {
    if (accuracy < 10.0) return Colors.green;
    if (accuracy <= 15.0) return Colors.yellow;
    return Colors.red;
  }
  ```[cite: 14]

## Calibration Factor Confirmation Workflow UI
1. **Input Stage:** User enters "Official Distance" into the factor calculation dialog[cite: 14].
2. **Preview Stage:** UI invokes `calculateNewFactor()` from `rally_lib` and presents a confirmation dialog showing `Current Factor` alongside `Calculated New Factor`[cite: 14].
3. **Commit Stage:**
   - **On Confirm:** Invokes `rally_lib` notifier to update and persist the new factor[cite: 14].
   - **On Cancel:** Closes modal without invoking state mutations[cite: 14].

## Numerical Entry Dialog State Handling
- **TextEditingController Handling:**
  - All factor and mileage entry dialogs maintain a `TextEditingController`[cite: 14].
  - **Clear Callback:** Tapping the "CLEAR" button invokes `controller.clear()`, resetting the field state to `""` and preserving active keyboard focus on the input field[cite: 14].

## UI Layout Rules & RenderFlex Overflow Prevention
To strictly prevent `RenderFlex` overflow exceptions across varying phone screen aspect ratios:

1. **Full-Screen Route Boilerplate Rule:**
   All secondary screens (`DetailsScreen`, `SettingsScreen`) must adopt this layout structure:
   ```dart
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(...),
       body: SafeArea(
         child: SingleChildScrollView(
           physics: const BouncingScrollPhysics(),
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 // Screen content components
               ],
             ),
           ),
         ),
       ),
     );
   }
   ```[cite: 14]