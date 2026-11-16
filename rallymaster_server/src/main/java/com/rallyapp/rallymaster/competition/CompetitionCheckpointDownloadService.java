package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.CompetitionCheckpointResponse;
import com.rallyapp.rallymaster.api.compete.CompetitionRoutePackageResponse;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPlanPersistence;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Supplies the selected route's checkpoint plan to its registered primary device. */
@Service
public class CompetitionCheckpointDownloadService {
  private final CheckpointPersistence checkpointPersistence;
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;
  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final RouteTimingPlanPersistence routeTimingPlanPersistence;

  public CompetitionCheckpointDownloadService(
      CheckpointPersistence checkpointPersistence,
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence,
      RallyConfigurationPersistence rallyConfigurationPersistence,
      RouteTimingPlanPersistence routeTimingPlanPersistence) {
    this.checkpointPersistence = checkpointPersistence;
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.routeTimingPlanPersistence = routeTimingPlanPersistence;
  }

  @Transactional(readOnly = true)
  public List<CompetitionCheckpointResponse> download(Long routeId, String deviceId) {
    if (routeId == null || deviceId == null || deviceId.isBlank()) {
      throw new CompetitionAuthenticationException();
    }
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(CompetitionAuthenticationException::new);
    if (route.getStatus() != RouteStatus.ACTIVE
        || rallyEntryPersistence.findFirstByRouteAndPrimaryDeviceId(routeId, deviceId) == null) {
      throw new CompetitionAuthenticationException();
    }
    return checkpointPersistence.findAllForRoute(routeId).stream()
        .sorted(Comparator.comparing(CheckpointEntity::getPosition,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .map(checkpoint -> toResponse(checkpoint, Map.of()))
        .toList();
  }

  /** Supplies the complete offline scoring configuration for a route. */
  @Transactional(readOnly = true)
  public CompetitionRoutePackageResponse downloadPackage(Long routeId, String deviceId) {
    RouteEntity route = authorizedActiveRoute(routeId, deviceId);
    RallyConfigurationEntity configuration = rallyConfigurationPersistence
        .findFirstByRally_Id(route.getRally().getId());
    RouteTimingPlanEntity plan = routeTimingPlanPersistence
        .findFirstByOrganizationIdAndRouteId(route.getOrganizationId(), routeId);
    if (configuration == null || plan == null) {
      throw new CompetitionAuthenticationException();
    }

    Map<Long, RouteTimingPointEntity> timingPoints = plan.getPoints().stream()
        .filter(point -> point.getRouteItem() != null && point.getRouteItem().getId() != null)
        .collect(java.util.stream.Collectors.toMap(
            point -> point.getRouteItem().getId(),
            point -> point));
    List<CompetitionCheckpointResponse> checkpoints = checkpointPersistence.findAllForRoute(routeId)
        .stream()
        .sorted(Comparator.comparing(CheckpointEntity::getPosition,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .map(checkpoint -> toResponse(checkpoint, timingPoints))
        .toList();

    return new CompetitionRoutePackageResponse(
        route.getId(),
        route.getRally().getId(),
        plan.getVersion(),
        plan.getCarZeroStartEpochMillis(),
        route.getTimeZone(),
        plan.getDistanceUnit() == null ? null : plan.getDistanceUnit().getName(),
        plan.getScoringUnit() == null ? null : plan.getScoringUnit().getName(),
        configuration.getCarStartIntervalMillis(),
        route.getMaximumCheckpointScore() == null
            ? configuration.getMaximumCheckpointScore() : route.getMaximumCheckpointScore(),
        configuration.getCheckpointAcquisitionRadiusMeters(),
        checkpoints);
  }

  private RouteEntity authorizedActiveRoute(Long routeId, String deviceId) {
    if (routeId == null || deviceId == null || deviceId.isBlank()) {
      throw new CompetitionAuthenticationException();
    }
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(CompetitionAuthenticationException::new);
    if (route.getStatus() != RouteStatus.ACTIVE
        || rallyEntryPersistence.findFirstByRouteAndPrimaryDeviceId(routeId, deviceId) == null) {
      throw new CompetitionAuthenticationException();
    }
    return route;
  }

  private CompetitionCheckpointResponse toResponse(
      CheckpointEntity checkpoint, Map<Long, RouteTimingPointEntity> timingPoints) {
    RouteTimingPointEntity timingPoint = timingPoints.get(checkpoint.getId());
    return new CompetitionCheckpointResponse(
        checkpoint.getId(),
        checkpoint.getCheckpointNumber(),
        checkpoint.getPosition(),
        timingPoint == null ? null : timingPoint.getSegmentNumber(),
        checkpoint.getCheckpointType() == null ? null : checkpoint.getCheckpointType().getName(),
        checkpoint.getName(),
        checkpoint.getLatitude(),
        checkpoint.getLongitude(),
        checkpoint.getHeading(),
        checkpoint.getDistance(),
        checkpoint.getNotes(),
        timingPoint == null ? null : timingPoint.getCarZeroIdealArrivalEpochMillis());
  }
}
