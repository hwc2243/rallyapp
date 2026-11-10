package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.CompetitionTelemetryUploadRequest;
import com.rallyapp.rallymaster.api.compete.CompetitionTelemetryUploadResponse;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryDataPersistence;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Stores diagnostic checkpoint evidence for one registered primary device. */
@Service
public class CompetitionTelemetryUploadService {
  private final CheckpointPersistence checkpointPersistence;
  private final CompetitorTelemetryPersistence competitorTelemetryPersistence;
  private final CompetitorTelemetryDataPersistence competitorTelemetryDataPersistence;
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;

  public CompetitionTelemetryUploadService(
      CheckpointPersistence checkpointPersistence,
      CompetitorTelemetryPersistence competitorTelemetryPersistence,
      CompetitorTelemetryDataPersistence competitorTelemetryDataPersistence,
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence) {
    this.checkpointPersistence = checkpointPersistence;
    this.competitorTelemetryPersistence = competitorTelemetryPersistence;
    this.competitorTelemetryDataPersistence = competitorTelemetryDataPersistence;
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional
  public CompetitionTelemetryUploadResponse upload(
      Long routeId,
      String deviceId,
      CompetitionTelemetryUploadRequest request) {
    if (request == null || request.checkpoints() == null) {
      throw new CompetitionTelemetryException("Checkpoint telemetry is required.");
    }
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(CompetitionAuthenticationException::new);
    if (route.getStatus() != RouteStatus.ACTIVE) {
      throw new CompetitionAuthenticationException();
    }
    RallyEntryEntity entry = rallyEntryPersistence.findFirstByRouteAndPrimaryDeviceId(routeId, deviceId);
    if (entry == null) {
      throw new CompetitionAuthenticationException();
    }

    int accepted = 0;
    int alreadyUploaded = 0;
    for (var record : request.checkpoints()) {
      validate(record);
      CheckpointEntity checkpoint = checkpointPersistence.findById(record.checkpointId())
          .orElseThrow(() -> new CompetitionTelemetryException("Checkpoint was not found."));
      if (checkpoint.getRoute() == null || !routeId.equals(checkpoint.getRoute().getId())) {
        throw new CompetitionTelemetryException("Checkpoint does not belong to the selected route.");
      }
      var occurredAt = record.occurredAt().atZone(ZoneOffset.UTC).toLocalDateTime();
      if (competitorTelemetryPersistence
          .findFirstByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt(
              entry.getOrganizationId(), entry.getId(), checkpoint.getId(), occurredAt) != null) {
        alreadyUploaded++;
        continue;
      }
      CompetitorTelemetryEntity telemetry = new CompetitorTelemetryEntity();
      telemetry.setRallyEntry(entry);
      telemetry.setRoute(route);
      telemetry.setCheckpoint(checkpoint);
      telemetry.setOrganizationId(entry.getOrganizationId());
      telemetry.setOccurredAt(occurredAt);
      telemetry.setInterceptLatitude(record.interceptLatitude());
      telemetry.setInterceptLongitude(record.interceptLongitude());
      telemetry.setInterceptHeading(record.interceptHeading());
      telemetry.setInterceptSpeed(record.interceptSpeed());
      telemetry.setInterceptAccuracy(record.interceptAccuracy());
      telemetry.setClosestDistanceMeters(record.closestDistanceMeters());
      telemetry = competitorTelemetryPersistence.save(telemetry);

      List<CompetitorTelemetryDataEntity> samples = new ArrayList<>();
      for (var sample : record.samples()) {
        CompetitorTelemetryDataEntity data = new CompetitorTelemetryDataEntity();
        data.setCompetitorTelemetry(telemetry);
        data.setOrganizationId(entry.getOrganizationId());
        data.setCapturedAt(sample.capturedAt().atZone(ZoneOffset.UTC).toLocalDateTime());
        data.setLatitude(sample.latitude());
        data.setLongitude(sample.longitude());
        data.setHeading(sample.heading());
        data.setSpeed(sample.speed());
        data.setAccuracy(sample.accuracy());
        data.setDistanceToCheckpointMeters(sample.distanceToCheckpointMeters());
        samples.add(data);
      }
      competitorTelemetryDataPersistence.saveAll(samples);
      accepted++;
    }
    return new CompetitionTelemetryUploadResponse(accepted, alreadyUploaded);
  }

  private static void validate(CompetitionTelemetryUploadRequest.CheckpointTelemetryRecord record) {
    if (record == null || record.checkpointId() == null || record.occurredAt() == null
        || record.interceptLatitude() == null || record.interceptLongitude() == null
        || record.interceptHeading() == null || record.interceptSpeed() == null
        || record.interceptAccuracy() == null || record.closestDistanceMeters() == null
        || record.samples() == null || record.samples().isEmpty()
        || !finite(record.interceptLatitude()) || !finite(record.interceptLongitude())
        || !finite(record.interceptHeading()) || !finite(record.interceptSpeed())
        || !finite(record.interceptAccuracy()) || !finite(record.closestDistanceMeters())) {
      throw new CompetitionTelemetryException("Checkpoint telemetry is incomplete.");
    }
    for (var sample : record.samples()) {
      if (sample == null || sample.capturedAt() == null || !finite(sample.latitude())
          || !finite(sample.longitude()) || !finite(sample.heading()) || !finite(sample.speed())
          || !finite(sample.accuracy()) || !finite(sample.distanceToCheckpointMeters())) {
        throw new CompetitionTelemetryException("GPS samples are incomplete.");
      }
    }
  }

  private static boolean finite(Double value) {
    return value != null && Double.isFinite(value);
  }

}
