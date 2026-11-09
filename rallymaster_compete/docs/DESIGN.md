# RallyMaster Compete Design

## System boundary

`rallymaster_compete` is a Flutter client backed by a new, competitor-facing
`/api/compete` API in `rallymaster_server`. The client owns local detection,
provisional scoring, and offline retry. The server owns event configuration,
registration validation, official results, and manual overrides.

## Proposed server data model

These are proposed additions; this document does not implement them.

| Model | Responsibility |
| --- | --- |
| `CompetitionEvent` | Per-rally competition settings: hashed event password, score unit, maximum score, discovery settings, status. |
| Route additions | Lifecycle status: `PLANNING`, `ACTIVE`, or `COMPLETED`, with the existing rally relationship. Route plan data is immutable after transition to `ACTIVE`. Publishing from `PLANNING` to `ACTIVE` captures the shared event password. |
| Checkpoint additions | Reuse the existing inherited route-item location and heading; add configurable acquisition radius (150 m default), planned-duration offset from segment start, restart delay, and optional per-control maximum score. Rename `PASSAGE_CONTROL` to `OFFCOURSE_CONTROL`. |
| `CompetitionTeam` | Driver/navigator, car number, selected route, calculated scheduled start, and competition state. Enforce `(rally_id, car_number)` uniqueness. |
| `CompetitionDevice` | Team installation identifier and `PRIMARY`/`BACKUP` role; exactly one primary device. Backup enrollment uses a one-time pairing QR. |
| `CheckpointCrossing` | Immutable crossing evidence, ideal/actual time, score, plan version, device role, review-required flag/reason, and idempotency key. |
| `TimeAllowance` | Auditable time adjustment with amount, sequence, device, and receipt state. |
| `CompetitorLocation` | Periodic primary-device monitoring location. |
| Message/SOS/withdrawal models | Event communication, acknowledgements, safety, and competition-state events. |

All competitor data remains tenant-scoped through the rally organization.

## Proposed API surface

| Endpoint | Purpose |
| --- | --- |
| `POST /api/compete/events/discover` | Find matching nearby rallies within one mile; no password is required. |
| `GET /api/compete/events/{rallyId}/routes` | List an event's active competitor routes; no password is required. |
| `POST /api/compete/events/{quickLink}/access` | Resolve a base-36 rally link and return its public competitor summary and active routes; password validation remains part of registration. |
| `POST /api/compete/registrations` | Validate password; create/resume primary registration for the selected route. |
| `POST /api/compete/registrations/{id}/backup-device` | Enroll backup device. |
| `GET /api/compete/teams/{id}/plan` | Download immutable, versioned competition plan. |
| `POST /api/compete/teams/{id}/crossings` | Idempotently submit primary crossing. |
| `POST /api/compete/teams/{id}/time-allowances` | Submit TA event. |
| `POST /api/compete/teams/{id}/locations` | Report primary-device location. |
| `GET /api/compete/teams/{id}/messages` | Retrieve pending announcements. |
| `POST /api/compete/messages/{id}/acknowledgements` | Acknowledge message. |
| `POST /api/compete/teams/{id}/sos` | Submit SOS. |
| `POST /api/compete/teams/{id}/withdrawal` | Withdraw team. |
| `GET /api/compete/teams/{id}/score` | Server-recognized score and overrides. |

Discovery requires the event password in a TLS-protected POST body; it is never
sent in a URL. A successful password check returns a short-lived credential
scoped only to that event. Registration upgrades this to a team-scoped
competitor credential, after which the shared password is discarded. Backup
enrollment uses a short-lived, one-time pairing credential represented by the
primary device's QR code.

## Versioned competition plan

The downloaded plan contains rally/route identity, event time zone, plan
version, official scheduled start, fixed one-minute-per-car-number start
offset, score unit, maximum-score policy, and ordered
checkpoints. Each checkpoint includes type, location, heading, radius,
intercept tolerance, duration offset from segment start, restart delay, and
score override. The route-selected configuration download includes the
150-metre default acquisition radius and any event/control overrides.

The plan is persisted atomically. A running team's plan must not change
silently; server policy must define plan replacement/version behavior.

## Client architecture

| Component | Responsibility |
| --- | --- |
| `competition_repository` | Durable registration, plan, results, outbox, and messages. |
| `compete_api_client` | Scoped `/api/compete` communication. |
| `registration_controller` | Nearby search, quick link/QR, route selection, and registration. |
| `location_pipeline` | GPS, accuracy, heading, and speed sample capture. |
| `checkpoint_detector` | Candidate radius, intercept, heading cone, tolerance, and first-pass rules. |
| `precision_estimator` | Kalman-filtered position inside a candidate control area. |
| `score_engine` | Deterministic segments, restart, TA, ideal-arrival, and score calculation. |
| `sync_engine` | Durable outbox retry, idempotent submissions, location, and messages. |
| `competition_screen` | Competitor controls, results, status, and alerts. |

The score engine and detector should be pure Dart modules, testable with
recorded location traces without Flutter.

## Crossing flow

```text
GPS sample
  -> quality and heading validation
  -> identify unfinalized checkpoints in acquisition radius
  -> retain raw samples and create filtered candidate samples
  -> calculate closest intercept and intercept time
  -> apply heading-cone and 40 m tolerance
  -> finalize first qualifying crossing
  -> calculate provisional score
  -> persist crossing and enqueue primary submission
```

Persisted evidence should include raw/filtered sample window, timestamp,
accuracy, heading, intercept distance, plan version, and detector version.

## Scoring model

```text
team start = scheduled start + car number × 1 minute
ideal arrival = active segment team start + planned duration
adjusted ideal = ideal arrival + cumulative TA for future controls
variance = actual intercept - adjusted ideal
score = min(maximum score, floor(abs(variance in configured score units)))
```

`RESTART` establishes the next segment time basis after its delay. A TA cannot
modify a previously finalized control; an appeal requires a RallyMaster manual
override.
`OFFCOURSE_CONTROL` applies maximum score to every remaining `TIMED_CONTROL`
in its segment. `START`, `TIME_CHECK`,
and `FINISH` record events but do not add direct score.

## Primary and backup behavior

Both devices execute the same local plan, detector, and score engine. Primary
events can sync. Backup crossing and score events remain local for later
review. The server rejects official scoring submitted by a non-primary device.
The primary issues a short-lived pairing QR; the backup scans it and receives
only the scoped information required for backup operation.

## Security and privacy

- Quick links are identifiers, not credentials.
- Password verification occurs over TLS and uses a server-side password hash.
- Registration is rate-limited.
- The app stores only the scoped credential in secure storage.
- SOS and withdrawal are durably recorded locally before network submission.

## Decision log

1. `START` is the indexed discovery location, including multi-route rallies;
   nearby-event date comparison uses the rally time zone. Existing rallies
   default to `America/New_York` until an organizer selects another zone.
2. Route lifecycle is `PLANNING`, `ACTIVE`, and `COMPLETED`; define who may
   make each transition. Publishing to `ACTIVE` requires an event password.
3. The default acquisition radius is 150 m; define allowed limits and whether
   per-control overrides are enabled initially.
4. Insufficient GPS evidence creates best-guess score with a review-required
   flag; RallyMaster can accept it, use backup evidence, or exclude it.
5. Define device-clock drift warning/blocking policy.
6. Scores use floor rounding before capping.
7. TA begins with `.5` and `1.0` minute buttons and only applies to future
   controls; forgotten TA uses manual override.
8. `OFFCOURSE_CONTROL` applies maximum score to all remaining timed controls
   in its segment; define whether another off-course event changes anything.
9. Define restart mileage and delay semantics.
10. Backup enrollment uses a primary-generated one-time QR pairing code;
    define its expiry and recovery behavior.
11. A route is immutable after `ACTIVE`; teams cannot change route after
    registration.
12. Define message delivery: polling versus push and retry/acknowledgement.
