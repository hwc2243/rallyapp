package com.rallyapp.rallymaster.api.external;

/** Editable, non-secret rally-wide planning defaults supplied by organizer clients. */
public record RallySettingsRequest(
    String distanceUnit,
    String scoringUnit,
    Long carStartIntervalMillis,
    Double defaultSpeed,
    Long defaultRestartIntervalMillis,
    Long defaultPauseDurationMillis) {
}
