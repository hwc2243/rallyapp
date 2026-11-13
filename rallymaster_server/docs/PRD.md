# Product Requirements Document: RallyMaster Server

## Purpose

RallyMaster Server is the system of record for organizations, rallies, route plans, competition configuration, competitor entry, and event telemetry. It serves the RallyMaster web application, RallyMaster mobile planner, and RallyMaster Compete.

## Goals

- Isolate data and authorization by organization.
- Support rally and route creation, planning, publishing, and review.
- Provide secure browser, organizer-mobile, and competitor API boundaries.
- Publish immutable event plans that allow Compete to score while offline.
- Preserve competitor evidence for organizer review and future overrides.

## Users and access

RallyMaster users authenticate through Keycloak and can belong to multiple organizations. Membership roles are `ADMIN`, `RALLYMASTER`, and `VIEWER`. Every organization-scoped operation must verify the caller's membership; client-supplied organization identifiers are not authorization.

Competitors do not require a RallyMaster account. They discover an event, choose an active route, authenticate with the event password, and register a team/device. The event password is not a user-account password.

## Rally planning

Rallies contain routes. Routes contain one canonical ordered list of polymorphic route items: `RouteInstruction` and `Checkpoint`. Canonical position orders both item types, while NRI and checkpoint numbers are separate sequences.

Routes progress through `PLANNING`, `ACTIVE`, and `COMPLETED`. An active route is immutable for competition purposes.

Rally creation captures these rally-wide units:

- Distance: `MILES` or `KILOMETERS`.
- Scoring: `SECONDS` or `CENTS`.

Distance units apply to all route distance and speed values; speed is MPH for miles and KPH for kilometers. Scoring units affect score conversion only and cannot vary by route.

Rallies also offer a rally-wide car-start interval plus optional default rally
speed, restart interval, and pause duration. The car-start interval is not
overridable by a route; a new route copies the remaining values as editable
route-level defaults.

NRIs support standard, begin/end free-zone, and begin/end transit types. Free zones and transits block checkpoint placement until the matching end NRI. Ending a transit records its user-confirmed duration, with a suggested value of 120 percent of measured transit time rounded up to a whole minute.

## Competition timing

The server publishes an immutable **car-zero** timing plan in milliseconds.
Compete clients add only `carNumber × carStartIntervalMillis` plus locally
recorded, forward-only time allowances. The car-start interval is configured
on the rally, defaults to one minute, and cannot be overridden on a route.
The most recent restart establishes the current segment basis. After a restart
pause, car zero begins the following segment on the first whole minute at or
after that pause.

The timing contract is specified in [COMPETITION_TIMING.md](COMPETITION_TIMING.md).

## Competition support

The server supports nearby START-based discovery, active-route lookup, event-password authentication, unique car-number registration, checkpoint-plan download, and checkpoint telemetry upload/review. Discovery uses the rally time zone and searches START checkpoints within one mile.

Telemetry stores the calculated intercept and GPS samples captured within the checkpoint acquisition radius. It is diagnostic evidence, not the final score record.

## Non-functional requirements

- PostgreSQL is the production datastore; H2 supports tests.
- Production traffic uses HTTPS and Keycloak OAuth/JWT authentication.
- Static assets, OAuth callbacks, the privacy page, and health checks remain public so they cannot disrupt browser login.
- Retried writes use idempotency where appropriate.
- ServiceBuilder-generated base code is regenerated from `service.xml`; custom logic belongs in extension services, repositories, controllers, and mappers.

## Deferred scope

- Final-score reconciliation and override workflow.
- Backup-device QR enrollment.
- Live location tracking, alerts, SOS, withdrawal, and public scoreboards.

