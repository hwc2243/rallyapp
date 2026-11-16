package com.rallyapp.rallymaster.api.compete;

import java.util.List;

/**
 * Immutable offline package used by a registered competitor device while it
 * runs a route.  Values are server-authoritative at the time of download.
 */
public record CompetitionRoutePackageResponse(
    Long routeId,
    Long rallyId,
    Long timingPlanVersion,
    Long carZeroStartEpochMillis,
    String timeZone,
    String distanceUnit,
    String scoringUnit,
    Long carStartIntervalMillis,
    Long maximumCheckpointScore,
    Double checkpointAcquisitionRadiusMeters,
    List<CompetitionCheckpointResponse> checkpoints) {
}
