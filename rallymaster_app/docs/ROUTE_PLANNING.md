# Route Planning Requirements

## Rally and route timing defaults

When creating a rally, RallyMaster captures the following rally-wide units and
optional planning defaults:

| Field | Meaning |
| --- | --- |
| Distance unit | Required `MILES` or `KILOMETERS` selection. It applies to every route, distance entry, and speed entry in the rally. |
| Scoring unit | Required `SECONDS` or `CENTS` selection. It applies to scoring only, not distance or speed. |

| Field | Meaning |
| --- | --- |
| Rally speed | Default speed for newly added NRIs. |
| Restart interval | Pause after a restart before car zero begins the next segment on a whole minute. |
| Pause duration | Default pause duration for newly added NRIs. |

When a route is created, any available rally defaults prepopulate the route
form and are saved as route-level values. The planner may override them for
that route. Later changes to rally defaults do not retroactively change a
route's saved values. Distance and scoring units are rally-wide and do not
have route overrides.

RallyMaster displays and accepts speed in MPH when the rally uses miles and
KPH when it uses kilometers. It displays and accepts all route distances in
the selected distance unit.

## NRI types and data

Each route instruction has a type. Initially supported types are:

- `STANDARD`
- `BEGIN_FREE_ZONE`
- `END_FREE_ZONE`
- `BEGIN_TRANSIT`
- `END_TRANSIT`

Each NRI captures an optional speed for the route portion beginning at that
instruction. The speed field is prepopulated in this order:

1. The latest earlier NRI that has a speed.
2. The route's configured rally speed.
3. Empty when neither value is available.

When the route has a configured rally speed, the NRI editor provides a
**Rally Speed** button that sets the field to that configured value.

Each NRI also offers an optional pause. Its field is prepopulated from the
route's pause duration when set. A pause is applied at that NRI and therefore
adds to the calculated time for all subsequent route items; it does not change
the ideal arrival at the NRI itself. This supports planned stops such as a stop
sign. When a route default exists, adjacent `+` and `−` controls add or
subtract that configured pause duration, respectively; they must identify the
actual increment (for example, `+ 0:30`), not imply a one-unit adjustment.

## Free-zone and transit state

Route planning maintains a sequential planning state derived from NRIs:

| NRI | State change | Checkpoint behavior |
| --- | --- | --- |
| `BEGIN_FREE_ZONE` | Enter free zone | Checkpoints cannot be added. |
| `END_FREE_ZONE` | Exit free zone | Checkpoints can be added again. |
| `BEGIN_TRANSIT` | Enter transit and start a monotonic elapsed-time timer | Checkpoints cannot be added. |
| `END_TRANSIT` | Exit transit and stop the timer | Checkpoints can be added again. |

The add-checkpoint action must be disabled with an explanation while the route
is in a free zone or transit. The state is reconstructed from saved route
items whenever a route is opened, so it remains correct after app restart or
editing.

## Transit duration

Creating `END_TRANSIT` prompts for a transit duration. The suggested duration
is based on the elapsed monotonic timer:

```text
suggested duration = ceil((elapsedMillis × 1.20) / 60,000) × 60,000
```

This means the suggested value includes 20 percent and is always rounded up to
a whole minute. The user may edit the suggested duration before saving the
NRI. The final duration is persisted with the `END_TRANSIT` instruction.

## Planning validation

- A free zone or transit may not begin while another such zone is active.
- An end instruction requires its matching active state.
- A route cannot be published while a free zone or transit is still open.
- Checkpoint creation is blocked, rather than silently allowed, while either
  state is active.
- Existing checkpoint and NRI ordering continues to use the route's canonical
  position; NRI sequence numbering remains independent of checkpoint numbers.
