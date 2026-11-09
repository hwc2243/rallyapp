package com.rallyapp.rallymaster.api.compete;

/** Non-sensitive confirmation retained by the primary competitor device. */
public record CompetitionRegistrationResponse(
    Long entryId,
    Long rallyId,
    Long routeId,
    Long carNumber) {
}
