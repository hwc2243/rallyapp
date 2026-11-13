# Product Requirements Document: RallyMaster Compete

## Purpose

RallyMaster Compete is the iOS and Android application used by a competitor
team during a TSD rally. It detects checkpoint crossings, calculates a
provisional score, works without cellular service, and reports competition
state to RallyMaster. RallyMaster remains the official system of record for
event configuration, results, and overrides.

## Goals

- Make rally entry and team registration quick, while preventing unintended
  registration.
- Record reliable checkpoint crossings in normal, poor, and temporarily lost
  GPS conditions.
- Calculate a transparent provisional score entirely on the device.
- Synchronize scoring and safety events whenever connectivity permits.
- Keep the active competition screen awake with `WakelockPlus`.

## Platforms and local operation

- Flutter application for iOS and Android.
- The active competition screen enables the wakelock and releases it when
  competition is no longer active.
- The selected route, checkpoint plan, score state, outbox, and pending
  announcements must remain available locally.

## Rally discovery and entry

### Find my event

**Find my event** obtains the device's GPS location and calls a new
RallyMaster `/compete` API. The competitor supplies the event password before
discovery. The server searches for matching rallies on the rally's current
local date whose `START` checkpoint is within one mile. The `START` checkpoint
is the definitive discovery location for the first release. The competitor
then chooses from the event's `ACTIVE` routes.

### Quick link

The competitor can enter or scan a QR code containing a rally quick link. The
link is the lower-case base-36 representation (`0-9`, `a-z`) of the rally ID.
After resolving it, the competitor chooses an active route.

### Registration

Registration collects driver first/last name, navigator first/last name, car
number, selected route, and the RallyMaster-generated event password. The
RallyMaster is prompted to set this password when publishing a route from
`PLANNING` to `ACTIVE`. The password is shared by event competitors and is
validated only after a competitor selects a route, immediately before team
registration. Discovery and active-route selection do not require a password,
so a competitor is not prompted when no matching rally is found. It is not a
RallyMaster user-account password. The server authoritatively enforces unique
car numbers within a rally.

## Team and devices

One team/car has one **primary** device and may register one backup device.

- The primary device submits official scoring events.
- The backup runs the same local detection and scoring logic but does not send
  scoring events to the server.
- RallyMaster can manually use backup evidence as an override if a primary
  result is missing or disputed. Automated reconciliation is out of scope.
- The primary device offers **Add backup device**, displaying a one-time QR
  pairing code. The backup app offers **Register as backup device** and scans
  that QR code to receive its team registration information.

## Checkpoint detection

Each checkpoint has location, required heading, and configuration. Once the
car enters the configured GPS acquisition radius, the app collects samples,
supplements them with a Kalman-filtered estimate, and calculates the closest
intercept of the vehicle course to the checkpoint.

The default acquisition radius is **150 metres**, downloaded as part of the
selected route's competition configuration. RallyMaster may configure the
value per event or control. At typical rally speeds of 40–45 mph, the default
provides about 15 seconds of in-radius travel for a near-center pass while the
separate 40-metre intercept criterion prevents a large radius from counting a
distant pass.

A crossing counts only when:

- it is the first qualifying pass for that checkpoint;
- the absolute heading difference is at most 60 degrees (a 120-degree total
  travel cone); and
- the calculated intercept is within 40 metres of the checkpoint.

Samples outside the acquisition radius do not participate in the intercept.
Wrong-direction and repeated passes are ignored. When insufficient GPS evidence
prevents a valid intercept, the app produces its best available crossing and
score estimate, flags it for RallyMaster review, and retains raw and filtered
evidence. RallyMaster may accept the competitor estimate, use backup-device
evidence, or exclude the checkpoint from final scoring.

## Timing and scoring

The phone clock is the competitor app's official time source. Times are stored
and submitted as UTC instants; the UI uses the rally's local time zone.

The server downloads a calculated **car-zero timing plan** in milliseconds.
Car zero begins at the official scheduled start. Each compete client derives
its own team timing by adding its car number multiplied by the rally-wide car
start interval (one minute by default; car 5 ordinarily adds five minutes).
A checkpoint duration is an offset from its segment start. The server
calculates each car-zero ideal arrival using the most recent restart time; the
app adds only the team offset and any valid, forward-only time allowances.

The client must not independently calculate restart or segment timing from
planner data. The downloaded plan contains the car-zero segment start and
ideal time for each checkpoint so scoring remains deterministic offline.

The RallyMaster configures score units:

- **seconds**: one point for every second early or late; or
- **cents**: one point for every one-hundredth of a minute early or late.

Early and late arrivals score equally. The absolute variance is rounded down
using floor semantics before a control maximum is applied (for example, `5.9`
score units becomes `5`). Total score is the sum of control scores and segment
penalties.

### Time allowance

The active screen provides `.5`-minute and `1.0`-minute TA (time allowance)
buttons for a known delay. A TA adjusts subsequent ideal arrival calculations,
is stored locally, and is submitted as an auditable event by the primary
device. A TA applies only to controls that have not yet finalized. A forgotten
TA requires a RallyMaster appeal and manual override.

## Checkpoint rules

`PASSAGE_CONTROL` will be renamed to `OFFCOURSE_CONTROL` before competition
support is implemented.

| Type | Behavior |
| --- | --- |
| `START` | Location stamp used for event discovery; not scored. |
| `TIMED_CONTROL` | Scored against its ideal arrival. |
| `TIME_CHECK` | Crossing is recorded but does not score. |
| `OFFCOURSE_CONTROL` | Team receives maximum score for every remaining `TIMED_CONTROL` in the segment. |
| `RESTART` | Ends a segment, resets mileage, applies the configured restart pause, and establishes the next car-zero segment start on the first whole minute after that pause. |
| `FINISH` | Records completion and notifies RallyMaster. |

A segment is the portion of a route between `RESTART` controls.

Once RallyMaster publishes a route as `ACTIVE`, its competition plan is
immutable. A registered team cannot change to another route.

## Units

The RallyMaster selects the rally-wide distance unit when creating the rally:
**miles** or **kilometers**. It applies to every route's distance and speed
values; speed is MPH for miles and KPH for kilometers. The RallyMaster also
selects the rally-wide scoring unit: **seconds** or **cents**. Scoring-unit
selection affects score conversion only. Both selections are included in the
downloaded competition plan and cannot vary by route.

## Offline and sync behavior

- The complete competition plan is downloaded before competition begins.
- Crossing detection and provisional scoring work fully offline.
- After each scored checkpoint, the primary device attempts submission.
- Failed events are stored in a durable outbox and retried periodically and on
  connectivity restoration.
- All event submission must be idempotent to prevent duplicate scores.
- The UI shows pending and synchronized state without blocking scoring.

## RallyMaster support, privacy, and safety

- Primary-device location is reported no more frequently than every 10 seconds.
- Location is visible only to authorized RallyMaster event staff.
- SOS sends current location and an optional message.
- A competitor can withdraw from competition.
- RallyMaster messages appear as acknowledgement-required popups. Scoring
  continues while a message is unacknowledged.

SOS escalation and acknowledgement workflows are deferred.

## Competition UX

The active screen is split between:

- a checkpoint table showing controls, provisional results, and scores; and
- a status/control area showing rally name, car number, TA, SOS, and withdrawal
  actions.

Portrait and landscape layouts will be designed in the initial active-scoring
slice.

## Deferred work

- Automated backup-device reconciliation.
- Complete SOS workflow and rescue escalation.
- Final real-time scoreboard.
- Advanced background tracking while the app is suspended.

## Open decisions

See [DESIGN.md](DESIGN.md) for the technical design and decision log.
