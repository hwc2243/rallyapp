# Product Requirement Document: Rally Lib (`rally_lib`)

## Library Overview
A headless, high-precision Dart/Flutter service library providing real-time GPS telemetry, dead-reckoning interpolation, distance accumulation, and state persistence for TSD (Time Speed Distance) Rallying[cite: 12, 13].

## Core Capabilities & Engine Specifications
1. **Background Telemetry & Processing:** Must continuously track location, calculate distance, and maintain internal state in the background when the consuming application is minimized or the device is locked[cite: 12, 13].
2. **Dual Odometer State Engine:**
   - **Total Odometer:** Tracks master cumulative distance[cite: 12, 13].
   - **Trip/Interval Odometer:** Tracks distance relative to interval resets[cite: 12, 13].
3. **GPS Source Flexibility:** Support mobile device internal GPS and external NMEA GPS streams[cite: 12, 13].
4. **Precision Math:** All internal calculations and distance states must maintain precision suitable for thousandths (0.000) display output[cite: 12, 13].

## Live Telemetry Data Structure
The library must maintain and continuously emit a real-time data structure containing:
- `total_odometer` (double)[cite: 12, 13]
- `interval_odometer` (double)[cite: 12, 13]
- `timestamp` (DateTime)[cite: 12, 13]
- `speed` (double)[cite: 12, 13]
- `bearing` (double, degrees 0°–360°)[cite: 12, 13]
- `latitude` (double)[cite: 12, 13]
- `longitude` (double)[cite: 12, 13]
- `gps_accuracy` (double, meters)[cite: 12, 13]

**Continuous Update Rule:** Telemetry parameters (`timestamp`, `speed`, `bearing`, `latitude`, `longitude`, `gps_accuracy`) must update continuously at the master refresh rate, even when odometer accumulation is paused or set to PARK[cite: 12, 13].

## Odometer Precision & Noise Filtering Logic
- **Stationary Suppression:** When speed drops below 0.8 m/s (~1.8 mph) for 3 consecutive seconds, the engine enters a locked stationary state and forces distance deltas to `0.0`[cite: 12, 13].
- **Monotonicity Guard (Distance Loss Prevention):**
  - While in **Forward** mode, total and interval mileage delta must be strictly non-decreasing (`delta >= 0.0`)[cite: 12, 13].
  - GPS resynchronization or drift corrections must never reduce accumulated distance[cite: 12, 13]. If a soft sync detects raw GPS distance is behind interpolated distance, accumulation pauses until physical position catches up[cite: 12, 13].
  - Decrements to distance are strictly forbidden unless FPR state is explicitly set to **Reverse**[cite: 12, 13].

## Startup Calibration Engine
- **Initial Stabilization:** Enters an automatic Calibration Mode on launch or GPS re-initialization[cite: 12, 13].
- **Distance Lock:** All distance accumulation is locked (`delta = 0.0`) during calibration to absorb initial GPS drift[cite: 12, 13].
- **Exit Condition:** Exits calibration mode once GPS accuracy reaches `< 15m` and positional readings stabilize across 3 consecutive updates[cite: 12, 13].

## Post-Calibration Stationary Lock (Zero-Drift Anchor)
- **Anchor Lock:** Enters Stationary Lock whenever speed drops below `0.8 m/s` for 3 seconds[cite: 12, 13].
- **Jitter Absorption:** Continuously resets reference coordinate anchor (`lastPosition = currentPosition`) on incoming GPS pulses without accumulating distance[cite: 12, 13].
- **Unlock Condition:** Unlocks only when speed exceeds `1.2 m/s` for 2 consecutive updates[cite: 12, 13].

## Low-Speed Precision & Windowed Tracking
- **Low-Speed Accrual:** Accurately accumulates distance at slow speeds (0.3 m/s to 1.2 m/s) without discarding movement as stationary noise[cite: 12, 13].
- **Multi-Sample Windowing:** Uses multi-sample time-window averaging across sequential coordinates to filter out GPS jitter[cite: 12, 13].
- **Monotonic Constraint:** Enforces `delta >= 0.0` in Forward mode during low-speed tracking[cite: 12, 13].

## Bearing Persistence Engine
- **Bearing Retention:** Retains calculated bearing continuously until a new valid bearing is determined[cite: 12, 13]. Does not drop to `0°` when stopping or crawling[cite: 12, 13].
- **Uninitialized State:** Represents uninitialized bearing as `null` / empty (allowing UI to display "N/A")[cite: 12, 13].

## Odometer Direction Control (FPR State Machine)
- **Forward (F):** Mileage accumulates normally (`dir_mult = 1.0`)[cite: 12, 13].
- **Park (P):** Accumulation strictly disabled (`dir_mult = 0.0`). Movement in Park is ignored upon returning to F/R[cite: 12, 13].
- **Reverse (R):** Distance is subtracted from totals (`dir_mult = -1.0`)[cite: 12, 13].

## Calculation & Calibration Factor Logic
- **Factor Formula:** Calculates proposed factors using:
  $$\text{New Factor} = \text{Current Factor} \times \left( \frac{\text{Official Distance}}{\text{Current Displayed Odometer Distance}} \right)$$
[cite: 12, 13]
- **State Triggers:** Exposes services for Reset, Hold/Release background tracking, Direct Distance Overrides, and Bump increment math[cite: 12, 13].

## Persistence Engine
- **Data Persistence:** Persists calibration factor, bump increment, unit preferences, and odometer states across app restarts and reboots[cite: 12, 13].

## Thread & Execution Performance
- **Non-Blocking Architecture:** High-frequency telemetry updates (20Hz) must execute without blocking host UI rendering isolates or causing frame drops[cite: 12, 13].