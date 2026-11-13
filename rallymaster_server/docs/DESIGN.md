# RallyMaster Server Design

## Architecture

RallyMaster Server is a Java 21 Spring Boot application using Spring MVC, Thymeleaf, Spring Security/OAuth2, Spring Data JPA, PostgreSQL, Jackson, and MapStruct. ServiceBuilder reads `src/main/resources/service.xml` during Maven source generation.

```text
Web browser / RallyMaster App / RallyMaster Compete
                        |
           MVC controllers and REST endpoints
                        |
       application and competition-domain services
                        |
ServiceBuilder services, MapStruct mappers, JPA repositories
                        |
                    PostgreSQL
```

## Persistent model

| Area | Entities | Responsibility |
| --- | --- | --- |
| Tenancy | `User`, `Organization`, `OrganizationMembership` | User roles and multi-organization access. |
| Planning | `Rally`, `Route`, `RouteItem`, `RouteInstruction`, `Checkpoint` | Rally route planning and ordered items. |
| Event | `RallyConfiguration` | Password hash, time zone, official start, scoring and discovery defaults. |
| Competitors | `RallyEntry` | Team names, unique car number, selected route, device IDs. |
| Evidence | `CompetitorTelemetry`, `CompetitorTelemetryData` | Checkpoint intercept and in-radius samples. |

`RouteItem` is an abstract parent using JPA joined inheritance. Multitenant entities include `organizationId`; service access uses the authenticated tenant context, not just a request header.

## Request boundaries

| Boundary | Path | Authentication | Use |
| --- | --- | --- | --- |
| Web | `/`, `/signin/**`, `/rally/**` | Keycloak browser login, except public paths | Organizer pages. |
| External API | `/api/external/**` | Bearer JWT plus authorized organization context | RallyMaster mobile app. |
| Competition API | `/api/compete/**` | Public discovery/registration or scoped competition credential | Compete app. |
| Operations | `/actuator/health` | Public | Health monitoring. |

Static content under `/css/**`, `/js/**`, `/images/**`, `/webjars/**`, and `/favicon.ico` is publicly allowed. This prevents asset requests from becoming the browser OAuth saved-request target.

`ContextInterceptor` establishes the browser user and selected organization in `SessionContext` and the HTTP session. `RestContextFilter` establishes the organization context for external bearer-token calls.

## Publishing and car-zero plans

Publishing validates a planning route, hashes/sets the event password, creates or updates rally configuration, calculates timing, and transitions the route to `ACTIVE` atomically. The published result contains car-zero segment starts and ideal checkpoint times in milliseconds. Clients only add their car-number offset and time allowances; they do not recalculate restarts.

```text
carZeroIdeal = currentCarZeroSegmentStart + checkpointOffsetMillis
teamIdeal    = carZeroIdeal + carNumber * carStartIntervalMillis
nextSegment  = ceilToWholeMinute(restartCarZeroIdeal + restartIntervalMillis)
```

The full contract is in [COMPETITION_TIMING.md](COMPETITION_TIMING.md).

## Profiles and deployment

- `local`: browser OAuth with local Keycloak and local PostgreSQL.
- `production`: browser OAuth and production PostgreSQL configuration.
- `keycloak`: JWT resource-server configuration for API deployments.
- unnamed development: permissive fallback only when named profiles are absent.

The server runs as the Spring Boot executable jar with the `production` profile. Secrets are profile/environment configuration, not mobile-client values.

## Extension rule

ServiceBuilder owns generated base classes. Custom repositories, service implementations, controllers, API DTOs, and competition services are the extension points. Preserve custom extension code before regeneration.

