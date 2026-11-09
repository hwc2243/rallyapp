# RallyMaster Compete Implementation Plan

## Approach

Build and verify small vertical slices. Each slice needs a server contract,
durable client behavior, and acceptance criteria. Do not build live scoring
until plan download and the local score engine are stable.

## Phase 0 — Foundation

**Deliverables:** Flutter shell, app identity, local-persistence and
secure-storage abstractions, shared competition models, `/api/compete` Spring
Security boundary, and tests.

**Verify:** App launches on iOS/Android; only intentional compete endpoints are
public; competitor flow does not accidentally reuse planner authentication.

## Phase 1 — Event discovery and route selection

**Deliverables:** `PLANNING`/`ACTIVE`/`COMPLETED` route lifecycle, Rally
time-zone field defaulting to `America/New_York`, indexed START discovery
location, event-password setup during publish, nearby/date/radius search,
base-36 quick-link access, manual/QR entry, active-route selection, and
password validation during selected-route registration UI.

**Verify:** Nearby/date boundaries are evaluated in rally time; invalid links
fail without exposing event data; invalid passwords reject registration; only
active routes are selectable; base-36 and radius calculations are unit tested.

## Phase 2 — Team and device registration

**Deliverables:** event/team/device server model, hashed password validation,
driver/navigator/car form, unique car-number validation, scheduled-start
calculation as car number × one minute, scoped primary credential, and
primary-generated QR backup-device enrollment.

**Verify:** Correct password and unique car register; duplicate car and invalid
password fail; registration restores after restart; backup cannot submit score;
expired or reused pairing QR is rejected.

## Phase 3 — Plan download and offline state

**Deliverables:** checkpoint/rally competition metadata (using existing
route-item location and heading), 150-metre default configurable acquisition
radius, segment-relative duration offset, renamed checkpoint type, versioned
plan endpoint/configuration download, transactional local plan storage,
read-only competition screen, and active-mode wakelock.

**Verify:** Competition screen works after network loss; ordered plan metadata
survives restart; a running plan is not silently replaced.

## Phase 4 — Deterministic score engine

**Deliverables:** pure-Dart segments, restarts, TA, ideal-arrival and score
logic; persisted provisional results; table score/sync display; floor rounding,
cap, remaining-segment off-course penalty, restart policies, and `.5`/`1.0`
minute TA controls.

**Verify:** Fixtures cover seconds/cents, symmetry, caps, TA, restarts, and
off-course penalties; identical traces always produce identical totals.

## Phase 5 — Checkpoint detection

**Deliverables:** foreground location pipeline, candidate radius, raw sample
window, filtered estimator, intercept time, 60-degree heading cone, 40-metre
tolerance, and first-pass finalization.

**Verify:** Recorded traces cover valid/wrong-direction/double passes, poor
accuracy, and speed changes; a valid checkpoint finalizes exactly once; an
insufficient-evidence case produces review-required best-guess evidence.

## Phase 6 — Primary sync and resilience

**Deliverables:** durable idempotent outbox, crossing/TA endpoints, retry on
timer/connectivity, visible sync states, and primary location reporting at no
more than once per 10 seconds.

**Verify:** Airplane-mode events sync once on recovery; retries do not duplicate
results; backup scoring remains local.

## Phase 7 — Safety, alerts, and completion

**Deliverables:** broadcast/acknowledgement support, SOS, withdrawal, finish
notification, and initial RallyMaster monitoring/override support.

**Verify:** Alerts do not stop scoring; SOS persists before submission; finish
and withdrawal are visible to event staff.

## Deferred

- Push notifications versus polling.
- Automated backup reconciliation.
- Advanced background location.
- Public scoreboard and final-results experience.

## Quality requirements

- Deterministic unit tests for time, score, and detection logic.
- API controller/service/integration tests, including tenant and competitor
  access controls.
- Anonymized location-trace fixtures only.
- Schema migrations before production deployment.
