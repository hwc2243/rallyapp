# RallyMaster Compete — Future Work

This list tracks work intentionally deferred while the competitor-registration
foundation is built.

## Publish an entire rally

- [ ] Add an authorized RallyMaster **Publish rally** action in the
  RallyMaster app. It should be available from the rally-level workflow rather
  than requiring the user to publish routes one at a time.
- [ ] Prompt once for the shared event password when publishing a rally.
- [ ] Add a transactional server operation such as
  `PUT /api/external/rally/{rallyId}/publish` that:
  - verifies the current user has access to the rally's organization;
  - validates the supplied password;
  - saves its BCrypt hash in the rally's private competition-event
    configuration;
  - changes every eligible `PLANNING` route in the rally to `ACTIVE`;
  - leaves `COMPLETED` routes unchanged;
  - returns a per-route result when a route cannot be published.
- [ ] Define and enforce route-readiness checks before activation, including a
  saved route plan and a valid `START` checkpoint. A failed route must not
  cause partially published routes.
- [ ] Confirm the final summary with the RallyMaster: number of routes
  activated, any skipped routes, and that the event password is now required
  for competitor registration.
- [ ] Decide whether the password may be changed after a rally is published.
  If it can, invalidate outstanding short-lived registration tokens.

## Competition registration and device access

- [ ] Implement nearby event discovery and active-route summaries without a
  password prompt.
- [ ] Implement `POST /api/compete/authenticate`, which is now available, in
  the RallyMaster Compete registration UI after the competitor chooses a
  route.
- [ ] Implement registration creation using the short-lived registration token
  and enforce unique car numbers within a rally.
- [ ] Issue a separate, revocable primary-device credential after registration.
  Use it—not the password-proof token—to download a team plan and submit
  scoring data.
- [ ] Implement backup-device QR enrollment and its local-only scoring rule.

## Competition configuration and auditability

- [ ] Add Rally time-zone configuration, defaulting to `America/New_York`.
- [ ] Add an auditable publish record: publisher, publish time, active routes,
  and a versioned immutable route plan for every registered team.
- [ ] Add password-attempt rate limiting and operational logging without
  logging passwords or registration tokens.
