# Competition Timing Contract

## Purpose

The server calculates and publishes the immutable **car-zero timing plan** for
an active route. This is the common timing basis for every RallyMaster Compete
installation. A compete client derives its team-specific timing locally so it
can score while offline.

## Car-zero and team timing

- The server calculates every ideal checkpoint time relative to car zero.
- Car zero begins at the rally's official start time.
- A compete client derives its team start by adding its car number multiplied
  by the rally-wide car-start interval to the car-zero start. The default is
  one minute, so car 5 ordinarily adds five minutes.
- The server sends the car-zero plan, not a separately calculated plan for
  every car. This makes the downloaded plan reusable, auditable, and stable.
- All internal timing values and calculations use whole milliseconds. Display
  formatting and score-unit conversion occur only at the application boundary.

## Segment and restart calculation

The most recent restart establishes the time basis for all later checkpoints.
For each segment, the server calculates a car-zero segment-start instant and
uses the checkpoint's offset within that segment to calculate its ideal time.

```text
carZeroIdealTime = latestCarZeroSegmentStart + checkpoint.segmentOffsetMillis
teamIdealTime    = carZeroIdealTime + carNumber * carStartIntervalMillis
```

The published plan must contain the calculated car-zero segment start and
ideal time for every checkpoint, along with source offsets. This allows the
client to calculate scores without needing a network request or reproducing
route-planning calculations.

At a restart, the configured restart interval is a pause that gives
competitors time to prepare for the next segment. The next car-zero segment
must start on the first whole minute at or after that pause ends:

```text
nextCarZeroSegmentStart = ceilToWholeMinute(
    restartCarZeroIdealTime + restartIntervalMillis)
```

The interval is therefore a planning value distinct from an NRI pause. Once a
route is published, the server is the only component that calculates and
publishes these car-zero segment-start values.

## Planner defaults and route snapshots

Rally-level optional defaults are:

| Setting | Purpose |
| --- | --- |
| Rally speed | Default speed used while planning route instructions. |
| Car start interval | Rally-wide separation between car zero and each subsequent car; routes cannot override it. |
| Restart interval | Pause after a restart before the next car-zero segment begins on a whole minute. |
| Pause duration | Default pause offered when creating an instruction. |

Route creation copies available rally defaults into route-level fields. A route
uses those copied values thereafter, allowing the rally's defaults to change
without altering an existing planned or active route.

## Rally-wide units

At rally creation, the organizer chooses the rally-wide distance unit
(`MILES` or `KILOMETERS`) and scoring unit (`SECONDS` or `CENTS`). These are
stored in the rally configuration and apply to every route in the rally; a
route cannot override them. Planner-entered distances and speeds use the
selected distance unit, so speed is expressed as MPH for miles and KPH for
kilometers. The scoring unit affects only score conversion, never distance or
speed entry.

The selected units must be included in every planner and compete plan download.
Changing units after routes contain planning data requires an explicit future
conversion workflow; it must not silently reinterpret stored values.

## Publish requirements

Before a route can become `ACTIVE`, the server must validate that its timing
inputs are complete, generate the car-zero plan in milliseconds, persist it as
part of the immutable published route plan, and expose it through the compete
plan-download contract. The server should reject a publish operation if a
required checkpoint offset, restart value, or segment relationship is invalid.

## Client responsibility

The client adds only its car-number offset and any locally recorded,
forward-only time allowances to the downloaded car-zero plan. It does not
recalculate the route's segment or restart timing.
