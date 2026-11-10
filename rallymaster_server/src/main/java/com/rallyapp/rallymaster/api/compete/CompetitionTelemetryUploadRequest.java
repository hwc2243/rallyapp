package com.rallyapp.rallymaster.api.compete;

import java.time.Instant;
import java.util.List;

/** Raw GPS evidence captured for successful checkpoint intercepts. */
public record CompetitionTelemetryUploadRequest(
    List<CheckpointTelemetryRecord> checkpoints) {
  public record CheckpointTelemetryRecord(
      Long checkpointId,
      Instant occurredAt,
      Double interceptLatitude,
      Double interceptLongitude,
      Double interceptHeading,
      Double interceptSpeed,
      Double interceptAccuracy,
      Double closestDistanceMeters,
      List<GpsSample> samples) {}

  public record GpsSample(
      Instant capturedAt,
      Double latitude,
      Double longitude,
      Double heading,
      Double speed,
      Double accuracy,
      Double distanceToCheckpointMeters) {}
}
