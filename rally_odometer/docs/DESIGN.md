# Design Specification: Rally Odometer

## Visual Hierarchy & Typography
- **Orientation:** Locked to Landscape Mode.
- **Typography:** - Use a **True Monospace** font (e.g., 'Courier' or 'Roboto Mono') for all mileage and time displays to prevent character-width "jitter."
  - **Mileage Size:** Maximum available height within the row (e.g., 80-100pt).
  - **Contrast:** High-contrast only. No gradients or shadows.
- **Layout:**
  - Split screen horizontally (50/50).
  - **Top Row:** Total Odometer (Left/Center), Current Time (Top-Right of row).
  - **Bottom Row:** Interval Odometer (Left/Center), Current Time (Top-Right of row).

## Speedometer Integration
- **Placement:** A slim, horizontal bar situated exactly between the Top (Total) and Bottom (Interval) rows.
- **Visuals:** - Centered text displaying "SPD: [Value] [Units]".
  - Font size should be significantly smaller than mileage (e.g., 24pt) but larger than the clock.
  - **Status Indicator:** The speed text should glow **Green** when the Speed-Sense filter is "ACTIVE" and turn **Dim Grey** when "STATIONARY" (paused).

## Button Layout & Interaction
- **Placement:** A vertical "Control Column" on the far right of the screen, occupying ~15% of the width.
- **Top Row Buttons:** [HOLD/RELEASE] stacked above [RESET].
- **Bottom Row Buttons:** [RESET] button only (centered vertically in row).
- **Sizing:** Minimum touch target of **88x88 pixels**.
- **Visual Feedback:** - **Hold Active:** The "Hold" button must turn **Bright Red** and the Mileage text should dim slightly (e.g., 70% opacity) to indicate the feed is frozen.
  - **Release:** Revert to standard High-Viz colors.

## Direction Control (FPR) Layout
- **Style:** A vertical Segmented Button or Toggle.
- **Visual Feedback:**
  - **Forward:** Standard Green text.  Labeled Forward
  - **Park:** White/Grey text; Mileage display should "dim" to show it is inactive. Labeled Park
  - **Reverse:** **Bold Red text** or Red background. The mileage numbers should turn Red to indicate they are "counting down." Labeled Reverse
- **Touch Target:** Large vertical area for easy toggling with a thumb while driving.

## GPS status
- **Visual:** a Satellite dish icon
- **Placement:** displayed at top centered between TOTAL label and time

## Wakelook
-- The screen must utilize a Wakelock to stay at 100% brightness indefinitely while the odometer is active.

## Themes
- **Default (Night):** Pure Black background (#000000).
- **Primary Text:** High-viz Green (#00FF00) for Total, High-viz Yellow (#FFFF00) for Interval.
- **Animations:** Strictly **Disabled**. All numerical updates must be instantaneous.
