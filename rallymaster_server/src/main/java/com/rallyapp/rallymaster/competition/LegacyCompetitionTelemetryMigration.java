package com.rallyapp.rallymaster.competition;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rallyapp.rallymaster.api.compete.CompetitionTelemetryUploadRequest.GpsSample;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryDataPersistence;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * One-time import of the legacy PostgreSQL {@code competition_telemetry}
 * large-object rows. Activate only with the {@code telemetry-migration}
 * profile after the generated tables have been created.
 *
 * <p>The legacy table is read only and is never altered or dropped. The
 * generated unique finder makes the import safe to run again after an
 * interrupted deployment.</p>
 */
@Component
@Profile("telemetry-migration")
public class LegacyCompetitionTelemetryMigration implements ApplicationRunner {
  private static final Logger logger = LoggerFactory.getLogger(LegacyCompetitionTelemetryMigration.class);
  private static final TypeReference<List<GpsSample>> GPS_SAMPLES = new TypeReference<>() {};

  private final JdbcTemplate jdbcTemplate;
  private final ObjectMapper objectMapper;
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;
  private final CheckpointPersistence checkpointPersistence;
  private final CompetitorTelemetryPersistence telemetryPersistence;
  private final CompetitorTelemetryDataPersistence dataPersistence;

  public LegacyCompetitionTelemetryMigration(
      JdbcTemplate jdbcTemplate,
      ObjectMapper objectMapper,
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence,
      CheckpointPersistence checkpointPersistence,
      CompetitorTelemetryPersistence telemetryPersistence,
      CompetitorTelemetryDataPersistence dataPersistence) {
    this.jdbcTemplate = jdbcTemplate;
    this.objectMapper = objectMapper;
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
    this.checkpointPersistence = checkpointPersistence;
    this.telemetryPersistence = telemetryPersistence;
    this.dataPersistence = dataPersistence;
  }

  @Override
  @Transactional
  public void run(ApplicationArguments args) throws Exception {
    List<LegacyTelemetryRow> legacyRows = jdbcTemplate.query(
        "select id, rally_entry_id, route_id, checkpoint_id, occurred_at, "
            + "intercept_latitude, intercept_longitude, intercept_heading, intercept_speed, "
            + "intercept_accuracy, closest_distance_meters, "
            + "convert_from(lo_get(samples_json), 'UTF8') as samples_json "
            + "from competition_telemetry order by id",
        (resultSet, rowNumber) -> new LegacyTelemetryRow(
            resultSet.getLong("id"),
            resultSet.getLong("rally_entry_id"),
            resultSet.getLong("route_id"),
            resultSet.getLong("checkpoint_id"),
            resultSet.getTimestamp("occurred_at"),
            resultSet.getDouble("intercept_latitude"),
            resultSet.getDouble("intercept_longitude"),
            resultSet.getDouble("intercept_heading"),
            resultSet.getDouble("intercept_speed"),
            resultSet.getDouble("intercept_accuracy"),
            resultSet.getDouble("closest_distance_meters"),
            resultSet.getString("samples_json")));

    int imported = 0;
    int alreadyImported = 0;
    for (LegacyTelemetryRow row : legacyRows) {
      RallyEntryEntity entry = rallyEntryPersistence.findById(row.rallyEntryId())
          .orElseThrow(() -> new IllegalStateException("Missing rally entry for legacy telemetry " + row.id()));
      RouteEntity route = routePersistence.findById(row.routeId())
          .orElseThrow(() -> new IllegalStateException("Missing route for legacy telemetry " + row.id()));
      CheckpointEntity checkpoint = checkpointPersistence.findById(row.checkpointId())
          .orElseThrow(() -> new IllegalStateException("Missing checkpoint for legacy telemetry " + row.id()));
      LocalDateTime occurredAt = row.occurredAt().toInstant().atZone(ZoneOffset.UTC).toLocalDateTime();
      if (telemetryPersistence.findFirstByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt(
          entry.getOrganizationId(), entry.getId(), checkpoint.getId(), occurredAt) != null) {
        alreadyImported++;
        continue;
      }
      CompetitorTelemetryEntity telemetry = new CompetitorTelemetryEntity();
      telemetry.setOrganizationId(entry.getOrganizationId());
      telemetry.setRallyEntry(entry);
      telemetry.setRoute(route);
      telemetry.setCheckpoint(checkpoint);
      telemetry.setOccurredAt(occurredAt);
      telemetry.setInterceptLatitude(row.interceptLatitude());
      telemetry.setInterceptLongitude(row.interceptLongitude());
      telemetry.setInterceptHeading(row.interceptHeading());
      telemetry.setInterceptSpeed(row.interceptSpeed());
      telemetry.setInterceptAccuracy(row.interceptAccuracy());
      telemetry.setClosestDistanceMeters(row.closestDistanceMeters());
      telemetry = telemetryPersistence.save(telemetry);

      List<CompetitorTelemetryDataEntity> samples = new ArrayList<>();
      for (GpsSample sample : objectMapper.readValue(row.samplesJson(), GPS_SAMPLES)) {
        CompetitorTelemetryDataEntity data = new CompetitorTelemetryDataEntity();
        data.setOrganizationId(entry.getOrganizationId());
        data.setCompetitorTelemetry(telemetry);
        data.setCapturedAt(sample.capturedAt().atZone(ZoneOffset.UTC).toLocalDateTime());
        data.setLatitude(sample.latitude());
        data.setLongitude(sample.longitude());
        data.setHeading(sample.heading());
        data.setSpeed(sample.speed());
        data.setAccuracy(sample.accuracy());
        data.setDistanceToCheckpointMeters(sample.distanceToCheckpointMeters());
        samples.add(data);
      }
      dataPersistence.saveAll(samples);
      imported++;
    }
    logger.info("Imported {} legacy telemetry records; {} were already imported. Legacy data was retained.",
        imported, alreadyImported);
  }

  private record LegacyTelemetryRow(
      long id,
      long rallyEntryId,
      long routeId,
      long checkpointId,
      Timestamp occurredAt,
      double interceptLatitude,
      double interceptLongitude,
      double interceptHeading,
      double interceptSpeed,
      double interceptAccuracy,
      double closestDistanceMeters,
      String samplesJson) {}
}
