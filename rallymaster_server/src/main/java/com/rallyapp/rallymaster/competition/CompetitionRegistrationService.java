package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.CompetitionRegistrationRequest;
import com.rallyapp.rallymaster.api.compete.CompetitionRegistrationResponse;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Creates one official, primary-device entry for a competitor team. */
@Service
public class CompetitionRegistrationService {
  private final CompetitionAuthenticationService authenticationService;
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;

  public CompetitionRegistrationService(
      CompetitionAuthenticationService authenticationService,
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence) {
    this.authenticationService = authenticationService;
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional
  public CompetitionRegistrationResponse register(CompetitionRegistrationRequest request) {
    validate(request);
    RouteEntity route = routePersistence.findById(request.routeId())
        .orElseThrow(() -> new CompetitionRegistrationException("The selected route is unavailable."));
    if (route.getStatus() != RouteStatus.ACTIVE || route.getRally() == null
        || !request.rallyId().equals(route.getRally().getId())) {
      throw new CompetitionRegistrationException("The selected route is unavailable.");
    }
    Long organizationId = route.getOrganizationId();
    if (organizationId == null) {
      throw new CompetitionRegistrationException("The selected route is unavailable.");
    }
    if (rallyEntryPersistence.findFirstByOrganizationIdAndRallyIdAndCarNumber(
        organizationId, request.rallyId(), request.carNumber()) != null) {
      throw new CompetitionRegistrationException("That car number is already registered for this rally.");
    }
    if (rallyEntryPersistence.findFirstByOrganizationIdAndRallyIdAndPrimaryDeviceId(
        organizationId, request.rallyId(), request.deviceId()) != null) {
      throw new CompetitionRegistrationException("This device is already registered for this rally.");
    }

    // Consumed only as part of this transaction; an invalid/duplicate entry rolls
    // back consumption so the competitor can correct the form and retry.
    authenticationService.consumeRegistrationToken(request.rallyId(), request.registrationToken());

    RallyEntryEntity entry = new RallyEntryEntity();
    entry.setRally(route.getRally());
    entry.setRoute(route);
    entry.setOrganizationId(organizationId);
    entry.setDriverFirstName(trim(request.driverFirstName()));
    entry.setDriverLastName(trim(request.driverLastName()));
    entry.setNavigatorFirstName(trim(request.navigatorFirstName()));
    entry.setNavigatorLastName(trim(request.navigatorLastName()));
    entry.setCarNumber(request.carNumber());
    entry.setPrimaryDeviceId(trim(request.deviceId()));
    try {
      entry = rallyEntryPersistence.saveAndFlush(entry);
    } catch (DataIntegrityViolationException ex) {
      throw new CompetitionRegistrationException(
          "That car number or device is already registered for this rally.");
    }
    return new CompetitionRegistrationResponse(
        entry.getId(), request.rallyId(), request.routeId(), entry.getCarNumber());
  }

  private static void validate(CompetitionRegistrationRequest request) {
    if (request == null || request.rallyId() == null || request.routeId() == null
        || request.carNumber() == null || request.carNumber() < 1
        || isBlank(request.registrationToken()) || isBlank(request.deviceId())
        || isBlank(request.driverFirstName()) || isBlank(request.driverLastName())
        || isBlank(request.navigatorFirstName()) || isBlank(request.navigatorLastName())) {
      throw new CompetitionRegistrationException("Complete team details and a positive car number are required.");
    }
    if (request.deviceId().trim().length() > 128) {
      throw new CompetitionRegistrationException("The device identifier is invalid.");
    }
  }

  private static boolean isBlank(String value) {
    return value == null || value.isBlank();
  }

  private static String trim(String value) {
    return value.trim();
  }
}
