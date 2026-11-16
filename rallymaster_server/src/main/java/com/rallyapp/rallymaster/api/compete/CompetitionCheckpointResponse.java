package com.rallyapp.rallymaster.api.compete;

/** Checkpoint plan data available to the registered primary competitor device. */
public record CompetitionCheckpointResponse(
    Long checkpointId,
    Long checkpointNumber,
    Long routePosition,
    Long segmentNumber,
    String checkpointType,
    String name,
    Double latitude,
    Double longitude,
    Integer heading,
    Double distance,
    String notes,
    Long carZeroIdealArrivalEpochMillis) {
}
