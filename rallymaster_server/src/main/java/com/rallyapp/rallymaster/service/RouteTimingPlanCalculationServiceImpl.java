package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPlanPersistence;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Server-authoritative computation of car-zero arrival times in milliseconds. */
@Service
public class RouteTimingPlanCalculationServiceImpl
    implements RouteTimingPlanCalculationService {
  private static final long MILLIS_PER_HOUR = 3_600_000L;
  private static final long MILLIS_PER_MINUTE = 60_000L;

  private final RoutePersistence routePersistence;
  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final RouteTimingPlanPersistence routeTimingPlanPersistence;

  public RouteTimingPlanCalculationServiceImpl(
      RoutePersistence routePersistence,
      RallyConfigurationPersistence rallyConfigurationPersistence,
      RouteTimingPlanPersistence routeTimingPlanPersistence) {
    this.routePersistence = routePersistence;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.routeTimingPlanPersistence = routeTimingPlanPersistence;
  }

  @Override
  @Transactional
  public RouteTimingPlanDTO calculateForRoute(Long routeId) throws ServiceException {
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(() -> new ServiceException("Route " + routeId + " was not found."));
    if (route.getRally() == null) {
      throw new ServiceException("Route " + routeId + " does not belong to a rally.");
    }
    RallyConfigurationEntity configuration = rallyConfigurationPersistence
        .findFirstByRally_Id(route.getRally().getId());
    validateHeader(route, configuration);

    List<RouteItemEntity> items = route.getItems().stream()
        .filter(item -> !Boolean.TRUE.equals(item.getDeleted()))
        .sorted(Comparator.comparing(RouteItemEntity::getPosition,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .toList();
    validateControls(items);

    RouteTimingPlanEntity plan = routeTimingPlanPersistence
        .findFirstByOrganizationIdAndRouteId(route.getOrganizationId(), routeId);
    if (plan == null) {
      plan = new RouteTimingPlanEntity();
      plan.setRoute(route);
      plan.setOrganizationId(route.getOrganizationId());
      plan.setVersion(1L);
      plan.setPoints(new ArrayList<>());
    } else {
      plan.setVersion((plan.getVersion() == null ? 0L : plan.getVersion()) + 1L);
      if (plan.getPoints() == null) {
        plan.setPoints(new ArrayList<>());
      } else {
        plan.getPoints().clear();
      }
    }
    plan.setCarZeroStartEpochMillis(route.getCarZeroStartEpochMillis());
    plan.setDistanceUnit(RouteTimingPlanDistanceUnit.valueOf(configuration.getDistanceUnit().name()));
    plan.setScoringUnit(RouteTimingPlanScoringUnit.valueOf(configuration.getScoringUnit().name()));

    long segmentNumber = 1L;
    long segmentStart = route.getCarZeroStartEpochMillis();
    long segmentOffset = 0L;
    double speed = effectiveSpeed(route, configuration);
    Double lastDistance = null;
    List<RouteTimingPointEntity> points = plan.getPoints();

    for (RouteItemEntity item : items) {
      if (item.getDistance() == null) {
        throw new ServiceException("Route item at position " + item.getPosition() + " has no distance.");
      }
      if (lastDistance != null) {
        double delta = item.getDistance() - lastDistance;
        if (delta < 0) delta = item.getDistance(); // mileage resets after a RESTART
        if (delta > 0 && speed <= 0) {
          throw new ServiceException("A positive speed is required to calculate route timing.");
        }
        segmentOffset += Math.round(delta / speed * MILLIS_PER_HOUR);
      }

      RouteTimingPointEntity point = new RouteTimingPointEntity();
      point.setOrganizationId(route.getOrganizationId());
      point.setRouteTimingPlan(plan);
      point.setRouteItem(item);
      point.setSegmentNumber(segmentNumber);
      point.setSegmentOffsetMillis(segmentOffset);
      point.setCarZeroSegmentStartEpochMillis(segmentStart);
      point.setCarZeroIdealArrivalEpochMillis(segmentStart + segmentOffset);
      points.add(point);

      if (item instanceof RouteInstructionEntity instruction) {
        if (instruction.getSpeed() != null) speed = instruction.getSpeed();
        if (instruction.getPauseDurationMillis() != null) {
          segmentOffset += instruction.getPauseDurationMillis();
        }
        if (instruction.getInstructionType() == RouteInstructionInstructionType.END_TRANSIT
            && instruction.getTransitDurationMillis() != null) {
          segmentOffset += instruction.getTransitDurationMillis();
        }
      }
      if (item instanceof CheckpointEntity checkpoint
          && checkpoint.getCheckpointType() == CheckpointCheckpointType.RESTART) {
        long restartInterval = effectiveRestartInterval(route, configuration);
        segmentStart = roundUpToMinute(segmentStart + segmentOffset + restartInterval);
        segmentNumber++;
        segmentOffset = 0L;
        lastDistance = 0.0;
      } else {
        lastDistance = item.getDistance();
      }
    }

    RouteTimingPlanEntity saved = routeTimingPlanPersistence.save(plan);
    return toDto(saved);
  }

  private static void validateHeader(RouteEntity route, RallyConfigurationEntity configuration)
      throws ServiceException {
    if (route.getCarZeroStartEpochMillis() == null) {
      throw new ServiceException("Route car-zero start time is required.");
    }
    if (route.getTimeZone() == null || route.getTimeZone().isBlank()) {
      throw new ServiceException("Route time zone is required.");
    }
    if (configuration == null || configuration.getDistanceUnit() == null
        || configuration.getScoringUnit() == null) {
      throw new ServiceException("Rally distance and scoring units are required.");
    }
  }

  private static void validateControls(List<RouteItemEntity> items) throws ServiceException {
    long starts = items.stream().filter(CheckpointEntity.class::isInstance)
        .map(CheckpointEntity.class::cast)
        .filter(item -> item.getCheckpointType() == CheckpointCheckpointType.START).count();
    long finishes = items.stream().filter(CheckpointEntity.class::isInstance)
        .map(CheckpointEntity.class::cast)
        .filter(item -> item.getCheckpointType() == CheckpointCheckpointType.FINISH).count();
    if (starts != 1) throw new ServiceException("A route timing plan requires exactly one START checkpoint.");
    if (finishes != 1) throw new ServiceException("A route timing plan requires exactly one FINISH checkpoint.");
  }

  private static double effectiveSpeed(RouteEntity route, RallyConfigurationEntity configuration)
      throws ServiceException {
    Double speed = route.getDefaultSpeed() != null
        ? route.getDefaultSpeed() : configuration.getDefaultSpeed();
    if (speed == null || speed <= 0) {
      throw new ServiceException("A route or rally default speed is required.");
    }
    return speed;
  }

  private static long effectiveRestartInterval(RouteEntity route,
      RallyConfigurationEntity configuration) {
    Long interval = route.getRestartIntervalMillis() != null
        ? route.getRestartIntervalMillis() : configuration.getDefaultRestartIntervalMillis();
    return interval == null ? 0L : interval;
  }

  private static long roundUpToMinute(long epochMillis) {
    return ((epochMillis + MILLIS_PER_MINUTE - 1) / MILLIS_PER_MINUTE) * MILLIS_PER_MINUTE;
  }

  private static RouteTimingPlanDTO toDto(RouteTimingPlanEntity plan) {
    RouteTimingPlanDTO dto = new RouteTimingPlanDTO();
    dto.setId(plan.getId());
    dto.setVersion(plan.getVersion());
    dto.setOrganizationId(plan.getOrganizationId());
    dto.setCarZeroStartEpochMillis(plan.getCarZeroStartEpochMillis());
    dto.setDistanceUnit(plan.getDistanceUnit());
    dto.setScoringUnit(plan.getScoringUnit());
    return dto;
  }
}
