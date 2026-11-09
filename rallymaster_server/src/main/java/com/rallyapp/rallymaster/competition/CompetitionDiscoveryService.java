package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.DiscoveredRallyResponse;
import com.rallyapp.rallymaster.api.compete.DiscoveredRouteResponse;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Locates published rallies near their definitive START checkpoints. */
@Service
public class CompetitionDiscoveryService {
  static final double DISCOVERY_RADIUS_METERS = 1609.344; // One statute mile.
  private static final ZoneId DEFAULT_TIME_ZONE = ZoneId.of("America/New_York");

  private final CheckpointPersistence checkpointPersistence;
  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final RoutePersistence routePersistence;

  public CompetitionDiscoveryService(
      CheckpointPersistence checkpointPersistence,
      RallyConfigurationPersistence rallyConfigurationPersistence,
      RoutePersistence routePersistence) {
    this.checkpointPersistence = checkpointPersistence;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional(readOnly = true)
  public List<DiscoveredRallyResponse> discover(double latitude, double longitude) {
    validateLocation(latitude, longitude);
    Map<Long, DiscoveredRally> rallies = new LinkedHashMap<>();
    for (RouteEntity route : routePersistence.findByStatus(RouteStatus.ACTIVE)) {
      if (route.getRally() == null || route.getRally().getId() == null
          || route.getRally().getDate() == null || route.getId() == null) {
        continue;
      }
      RallyConfigurationEntity configuration =
          rallyConfigurationPersistence.findFirstByRally_Id(route.getRally().getId());
      if (!isToday(route.getRally().getDate(), configuration)) {
        continue;
      }
      List<CheckpointEntity> starts = checkpointPersistence.findAllForRouteAndCheckpointType(
          route.getId(), CheckpointCheckpointType.START);
      if (starts.size() != 1) {
        continue;
      }
      CheckpointEntity start = starts.getFirst();
      if (start.getLatitude() == null || start.getLongitude() == null
          || distanceMeters(latitude, longitude, start.getLatitude(), start.getLongitude())
              > DISCOVERY_RADIUS_METERS) {
        continue;
      }
      rallies.computeIfAbsent(route.getRally().getId(), ignored -> new DiscoveredRally(route));
    }
    return rallies.values().stream().map(DiscoveredRally::toResponse).toList();
  }

  @Transactional(readOnly = true)
  public List<DiscoveredRouteResponse> activeRoutes(Long rallyId) {
    if (rallyId == null) {
      throw new IllegalArgumentException("A rally id is required.");
    }
    RallyConfigurationEntity configuration =
        rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
    return routePersistence.findByRally_IdAndStatus(rallyId, RouteStatus.ACTIVE).stream()
        .filter(route -> route.getRally() != null && route.getRally().getDate() != null)
        .filter(route -> isToday(route.getRally().getDate(), configuration))
        .map(route -> new DiscoveredRouteResponse(route.getId(), route.getName()))
        .toList();
  }

  static double distanceMeters(double firstLatitude, double firstLongitude,
      double secondLatitude, double secondLongitude) {
    double latitudeRadians = Math.toRadians(secondLatitude - firstLatitude);
    double longitudeRadians = Math.toRadians(secondLongitude - firstLongitude);
    double a = Math.sin(latitudeRadians / 2) * Math.sin(latitudeRadians / 2)
        + Math.cos(Math.toRadians(firstLatitude)) * Math.cos(Math.toRadians(secondLatitude))
        * Math.sin(longitudeRadians / 2) * Math.sin(longitudeRadians / 2);
    return 6_371_000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private static boolean isToday(LocalDate rallyDate, RallyConfigurationEntity configuration) {
    ZoneId timeZone = DEFAULT_TIME_ZONE;
    if (configuration != null && configuration.getTimeZone() != null
        && !configuration.getTimeZone().isBlank()) {
      try {
        timeZone = ZoneId.of(configuration.getTimeZone());
      } catch (RuntimeException ignored) {
        // A malformed configuration must not make public discovery fail.
      }
    }
    return rallyDate.equals(LocalDate.now(timeZone));
  }

  private static void validateLocation(double latitude, double longitude) {
    if (!Double.isFinite(latitude) || !Double.isFinite(longitude)
        || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new IllegalArgumentException("A valid latitude and longitude are required.");
    }
  }

  private static final class DiscoveredRally {
    private final RouteEntity firstRoute;
    private DiscoveredRally(RouteEntity firstRoute) {
      this.firstRoute = firstRoute;
    }

    private DiscoveredRallyResponse toResponse() {
      return new DiscoveredRallyResponse(
          firstRoute.getRally().getId(),
          firstRoute.getRally().getName(),
          firstRoute.getRally().getDate());
    }
  }
}
