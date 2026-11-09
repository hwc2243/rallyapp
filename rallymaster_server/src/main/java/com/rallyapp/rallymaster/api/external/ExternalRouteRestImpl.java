package com.rallyapp.rallymaster.api.external;

import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.competition.CompetitionAuthenticationService;
import com.rallyapp.rallymaster.service.ServiceException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRestImpl;

@RestController
@RequestMapping("/api/external/route")
public class ExternalRouteRestImpl
   extends BaseExternalRouteRestImpl
   implements ExternalRouteRest
{
  private static final Logger logger = LoggerFactory.getLogger(ExternalRouteRestImpl.class);

  private final CompetitionAuthenticationService competitionAuthenticationService;

  public ExternalRouteRestImpl(CompetitionAuthenticationService competitionAuthenticationService) {
    this.competitionAuthenticationService = competitionAuthenticationService;
  }

  @PutMapping("/{routeId}/publish")
  public ResponseEntity<RouteDTO> publishRoute(
      @PathVariable Long routeId,
      @RequestBody PublishRouteRequest request) {
    try {
      return ResponseEntity.ok(
          competitionAuthenticationService.publish(routeId, request.eventPassword()));
    } catch (ServiceException ex) {
      logger.warn("Unable to publish route {}: {}", routeId, ex.getMessage());
      return ResponseEntity.badRequest().build();
    }
  }

  @PutMapping("/{routeId}/items")
  @Override
  public ResponseEntity<RoutePlanDTO> saveRoutePlan(
      @PathVariable Long routeId,
      @RequestBody RoutePlanDTO plan) {
    try {
      RouteDTO route = routeService.get(routeId);
      if (route == null) {
        return ResponseEntity.notFound().build();
      }
      return ResponseEntity.ok(routeService.savePlan(routeId, plan));
    } catch (ServiceException ex) {
      logger.warn("Unable to save route plan for route {}: {}", routeId, ex.getMessage(), ex);
      if (ex.getMessage() != null && ex.getMessage().startsWith("Access denied")) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
      return ResponseEntity.internalServerError().build();
    }
  }
}
