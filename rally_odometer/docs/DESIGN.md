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

## Themes
- **Default (Night):** Pure Black background (#000000).
- **Primary Text:** High-viz Green (#00FF00) for Total, High-viz Yellow (#FFFF00) for Interval.
- **Animations:** Strictly **Disabled**. All numerical updates must be instantaneous.
