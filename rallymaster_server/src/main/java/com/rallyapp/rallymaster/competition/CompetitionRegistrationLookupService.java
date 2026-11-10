package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.CompetitionRegistrationResponse;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Resolves an existing primary-device registration when an app is resumed. */
@Service
public class CompetitionRegistrationLookupService {
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;

  public CompetitionRegistrationLookupService(
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence) {
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional(readOnly = true)
  public CompetitionRegistrationResponse find(Long routeId, String deviceId) {
    if (routeId == null || deviceId == null || deviceId.isBlank()) return null;
    RouteEntity route = routePersistence.findById(routeId).orElse(null);
    if (route == null || route.getStatus() != RouteStatus.ACTIVE || route.getRally() == null) {
      return null;
    }
    RallyEntryEntity entry =
        rallyEntryPersistence.findFirstByRouteAndPrimaryDeviceId(routeId, deviceId);
    if (entry == null) return null;
    return new CompetitionRegistrationResponse(
        entry.getId(), route.getRally().getId(), route.getId(), entry.getCarNumber());
  }
}
