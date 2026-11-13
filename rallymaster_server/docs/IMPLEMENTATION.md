# RallyMaster Server Implementation Plan

## Approach

Build small vertical slices. For a ServiceBuilder-owned model change: update `service.xml`, regenerate, add custom behavior only in extension classes, secure the request boundary, and add tests. Use production schema migrations; do not recreate or discard live data.

## Existing foundation

- Spring Boot, JPA, PostgreSQL production profile, H2 tests, Thymeleaf, and Bootstrap web UI.
- Keycloak browser login/logout and JWT protection for the external API.
- Organization membership roles, selected-organization context, and tenant-aware generated services.
- Rally, route, polymorphic item, NRI, checkpoint, publishing, discovery, registration, checkpoint download, and telemetry support.

## Phase 1 — Rally and route planning defaults

**Deliver:** Rally-wide distance/scoring units; rally speed, restart interval, and pause defaults; copied route-level defaults; web and external/mobile creation/update contracts.

**Verify:** Units are required at rally creation, all routes share them, new routes inherit defaults, and an existing route is not changed when a rally default later changes.

## Phase 2 — NRI semantics

**Deliver:** NRI type, speed, pause, and transit-duration fields; free-zone and transit state validation; checkpoint placement restrictions.

**Verify:** Nested/unmatched state transitions fail, open zones prevent publishing, and NRI pauses affect subsequent timing only.

## Phase 3 — Car-zero timing service

**Deliver:** Pure Java timing calculator, immutable published-plan model, millisecond timing fields, whole-minute restart rounding, and versioned competition plan download.

**Verify:** Fixtures cover multiple segments, car offsets, NRI pauses, restart rounding, seconds/cents conversion, and invalid-plan rejection.

## Phase 4 — Competition score exchange

**Deliver:** Idempotent crossing/TA contracts, provisional-result persistence, and organizer score/review data. Preserve primary-device authority and backup evidence for manual review.

**Verify:** Retried writes do not duplicate results; non-primary and cross-organization writes are rejected; each result links to a plan version.

## Phase 5 — Operations

**Deliver:** Backup-device enrollment, live tracking, alerts, SOS, withdrawal, final-score overrides, and route completion.

## Required test coverage

- Timing, discovery radius, input-validation, and idempotency unit tests.
- Tenant access, publishing, plan immutability, and telemetry ownership integration tests.
- MVC/security tests for public assets, OAuth callback, privacy page, and protected organizer routes.
- API tests for JWT, organization context, competition credentials, and errors.
- Migration rehearsal before any production table changes.

## Build and deploy

```bash
./mvnw test
./mvnw package
java -jar target/rallymaster-server-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=production
```

Before deployment, back up PostgreSQL, apply the migration, confirm `/actuator/health`, and exercise browser login plus a protected API request.

