package com.rallyapp.rallymaster.api.external;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationService;
import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.service.RallyConfigurationService;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.DeleteMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRestImpl;

@RestController
@RequestMapping("/api/external/rally")
public class ExternalRallyRestImpl
   extends BaseExternalRallyRestImpl
   implements ExternalRallyRest
{
  private final CompetitionAuthenticationService competitionAuthenticationService;
  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final RallyConfigurationService rallyConfigurationService;
  private final RouteService routeService;

  public ExternalRallyRestImpl(
      CompetitionAuthenticationService competitionAuthenticationService,
      RallyConfigurationPersistence rallyConfigurationPersistence,
      RallyConfigurationService rallyConfigurationService,
      RouteService routeService) {
    this.competitionAuthenticationService = competitionAuthenticationService;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.rallyConfigurationService = rallyConfigurationService;
    this.routeService = routeService;
  }

  @GetMapping("/{rallyId}/publish-status")
  public ResponseEntity<RallyPublishStatusResponse> getPublishStatus(
      @PathVariable Long rallyId) {
    try {
      if (rallyService.get(rallyId) == null) {
        return ResponseEntity.notFound().build();
      }
      return ResponseEntity.ok(new RallyPublishStatusResponse(
          competitionAuthenticationService.hasEventPassword(rallyId)));
    } catch (ServiceException ex) {
      return ResponseEntity.status(403).build();
    }
  }

  @DeleteMapping("/{id}")
  @Override
  public ResponseEntity<Void> deleteRally(@PathVariable Long id) {
    try {
      rallyService.delete(id);
      return ResponseEntity.noContent().build();
    } catch (ServiceException ex) {
      if (ex.getMessage() != null && ex.getMessage().contains("active or completed")) {
        return ResponseEntity.status(HttpStatus.CONFLICT).build();
      }
      if (ex.getMessage() != null && ex.getMessage().contains("not found")) {
        return ResponseEntity.notFound().build();
      }
      return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
    }
  }

  @GetMapping("/{rallyId}/settings")
  public ResponseEntity<RallySettingsResponse> getSettings(@PathVariable Long rallyId) {
    try {
      if (rallyService.get(rallyId) == null) return ResponseEntity.notFound().build();
      RallyConfigurationDTO settings = findSettings(rallyId);
      return ResponseEntity.ok(toResponse(settings == null ? defaults(rallyId) : settings));
    } catch (ServiceException ex) {
      return ResponseEntity.status(403).build();
    }
  }

  @PutMapping("/{rallyId}/settings")
  public ResponseEntity<RallySettingsResponse> saveSettings(
      @PathVariable Long rallyId, @RequestBody RallySettingsRequest request) {
    try {
      RallyDTO rally = rallyService.get(rallyId);
      if (rally == null) return ResponseEntity.notFound().build();
      if (routeService.findByRallyId(rallyId).stream().anyMatch(route -> route.getStatus() == RouteStatus.ACTIVE)) {
        return ResponseEntity.status(409).build();
      }
      RallyConfigurationDTO settings = findSettings(rallyId);
      if (settings == null) settings = defaults(rallyId);
      apply(request, settings);
      RallyConfigurationDTO saved = settings.getId() == null
          ? rallyConfigurationService.create(settings)
          : rallyConfigurationService.update(settings);
      return ResponseEntity.ok(toResponse(saved));
    } catch (IllegalArgumentException ex) {
      return ResponseEntity.badRequest().build();
    } catch (ServiceException ex) {
      return ResponseEntity.status(403).build();
    }
  }

  private RallyConfigurationDTO findSettings(Long rallyId) {
    var entity = rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
    if (entity == null) return null;
    RallyConfigurationDTO dto = new RallyConfigurationDTO();
    dto.setId(entity.getId());
    dto.setRallyId(rallyId);
    dto.setOrganizationId(entity.getOrganizationId());
    dto.setDistanceUnit(entity.getDistanceUnit());
    dto.setScoringUnit(entity.getScoringUnit());
    dto.setCarStartIntervalMillis(entity.getCarStartIntervalMillis());
    dto.setDefaultSpeed(entity.getDefaultSpeed());
    dto.setDefaultRestartIntervalMillis(entity.getDefaultRestartIntervalMillis());
    dto.setDefaultPauseDurationMillis(entity.getDefaultPauseDurationMillis());
    return dto;
  }

  private RallyConfigurationDTO defaults(Long rallyId) throws ServiceException {
    RallyDTO rally = rallyService.get(rallyId);
    RallyConfigurationDTO settings = new RallyConfigurationDTO();
    settings.setRallyId(rallyId);
    settings.setOrganizationId(rally.getOrganizationId());
    settings.setDistanceUnit(RallyConfigurationDistanceUnit.MILES);
    settings.setScoringUnit(RallyConfigurationScoringUnit.SECONDS);
    settings.setCarStartIntervalMillis(60_000L);
    return settings;
  }

  private void apply(RallySettingsRequest request, RallyConfigurationDTO settings) {
    settings.setDistanceUnit(RallyConfigurationDistanceUnit.valueOf(request.distanceUnit()));
    settings.setScoringUnit(RallyConfigurationScoringUnit.valueOf(request.scoringUnit()));
    if (request.carStartIntervalMillis() == null || request.carStartIntervalMillis() <= 0) {
      throw new IllegalArgumentException("carStartIntervalMillis");
    }
    settings.setCarStartIntervalMillis(request.carStartIntervalMillis());
    settings.setDefaultSpeed(request.defaultSpeed());
    settings.setDefaultRestartIntervalMillis(request.defaultRestartIntervalMillis());
    settings.setDefaultPauseDurationMillis(request.defaultPauseDurationMillis());
  }

  private static RallySettingsResponse toResponse(RallyConfigurationDTO settings) {
    return new RallySettingsResponse(
        settings.getDistanceUnit().name(), settings.getScoringUnit().name(),
        settings.getCarStartIntervalMillis(), settings.getDefaultSpeed(),
        settings.getDefaultRestartIntervalMillis(), settings.getDefaultPauseDurationMillis());
  }
}
