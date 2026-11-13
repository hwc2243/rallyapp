package com.rallyapp.rallymaster.api.external;

/** Rally-wide settings safe to return to organizer clients; deliberately omits eventPasswordHash. */
public record RallySettingsResponse(
    String distanceUnit,
    String scoringUnit,
    Long carStartIntervalMillis,
    Double defaultSpeed,
    Long defaultRestartIntervalMillis,
    Long defaultPauseDurationMillis) {
}
