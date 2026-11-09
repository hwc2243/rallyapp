package com.rallyapp.rallymaster.api.compete;

/** Team information supplied by a competitor after event-password authentication. */
public record CompetitionRegistrationRequest(
    Long rallyId,
    Long routeId,
    String registrationToken,
    String driverFirstName,
    String driverLastName,
    String navigatorFirstName,
    String navigatorLastName,
    Long carNumber,
    String deviceId) {
}
