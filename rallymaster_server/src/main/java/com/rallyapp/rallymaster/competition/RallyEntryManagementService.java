package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.external.CompetitorEntryResponse;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.spring.SessionContext;
import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Organization-scoped administration of competitor entries.
 *
 * <p>This service is deliberately used only by the authenticated external
 * RallyMaster API, never by the public competitor API.</p>
 */
@Service
public class RallyEntryManagementService {
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;

  public RallyEntryManagementService(
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence) {
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional(readOnly = true)
  public List<CompetitorEntryResponse> listForRoute(Long routeId) {
    Long organizationId = authorizedRoute(routeId).getOrganizationId();
    return rallyEntryPersistence.findByOrganizationIdAndRoute_Id(organizationId, routeId).stream()
        .sorted(Comparator.comparing(RallyEntryEntity::getCarNumber,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .map(this::toResponse)
        .toList();
  }

  @Transactional
  public void deleteForRoute(Long routeId, Long entryId) {
    rallyEntryPersistence.delete(entryForRoute(authorizedRoute(routeId), entryId));
  }

  @Transactional(readOnly = true)
  public CompetitorEntryResponse getForRoute(Long routeId, Long entryId) {
    return toResponse(entryForRoute(authorizedRoute(routeId), entryId));
  }

  /**
   * Updates the editable team details while preserving registered device ids.
   * A car number is unique across the rally, even when it has multiple routes.
   */
  @Transactional
  public CompetitorEntryResponse updateForRoute(
      Long routeId,
      Long entryId,
      Long carNumber,
      String driverFirstName,
      String driverLastName,
      String navigatorFirstName,
      String navigatorLastName) {
    RouteEntity route = authorizedRoute(routeId);
    RallyEntryEntity entry = entryForRoute(route, entryId);
    if (carNumber == null || carNumber < 1 || isBlank(driverFirstName)
        || isBlank(driverLastName) || isBlank(navigatorFirstName)
        || isBlank(navigatorLastName) || route.getRally() == null) {
      throw new IllegalArgumentException("Complete team details and a positive car number are required.");
    }
    RallyEntryEntity conflict = rallyEntryPersistence
        .findFirstByOrganizationIdAndRallyIdAndCarNumber(
            route.getOrganizationId(), route.getRally().getId(), carNumber);
    if (conflict != null && !entry.getId().equals(conflict.getId())) {
      throw new IllegalArgumentException("That car number is already registered for this rally.");
    }
    entry.setCarNumber(carNumber);
    entry.setDriverFirstName(driverFirstName.trim());
    entry.setDriverLastName(driverLastName.trim());
    entry.setNavigatorFirstName(navigatorFirstName.trim());
    entry.setNavigatorLastName(navigatorLastName.trim());
    return toResponse(rallyEntryPersistence.save(entry));
  }

  private RallyEntryEntity entryForRoute(RouteEntity route, Long entryId) {
    RallyEntryEntity entry = rallyEntryPersistence.findById(entryId)
        .orElseThrow(() -> new NoSuchElementException("Competitor entry was not found."));
    if (!route.getOrganizationId().equals(entry.getOrganizationId())
        || entry.getRoute() == null
        || !route.getId().equals(entry.getRoute().getId())) {
      // Treat entries outside this route as absent so ids cannot be probed.
      throw new NoSuchElementException("Competitor entry was not found.");
    }
    return entry;
  }

  private RouteEntity authorizedRoute(Long routeId) {
    OrganizationDTO organization = SessionContext.getCurrentOrganization();
    if (organization == null || organization.getId() == null) {
      throw new AccessDeniedException("An organization context is required.");
    }
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(() -> new NoSuchElementException("Route was not found."));
    if (!organization.getId().equals(route.getOrganizationId())) {
      throw new AccessDeniedException("The selected route belongs to another organization.");
    }
    return route;
  }

  private CompetitorEntryResponse toResponse(RallyEntryEntity entry) {
    return new CompetitorEntryResponse(
        entry.getId(),
        entry.getCarNumber(),
        entry.getDriverFirstName(),
        entry.getDriverLastName(),
        entry.getNavigatorFirstName(),
        entry.getNavigatorLastName());
  }

  private static boolean isBlank(String value) {
    return value == null || value.isBlank();
  }
}
