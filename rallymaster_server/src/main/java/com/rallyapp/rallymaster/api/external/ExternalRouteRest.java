package com.rallyapp.rallymaster.api.external;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRest;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import java.util.List;
import org.springframework.http.ResponseEntity;

public interface ExternalRouteRest extends BaseExternalRouteRest
{
  ResponseEntity<RoutePlanDTO> saveRoutePlan(Long routeId, RoutePlanDTO plan);

  ResponseEntity<RouteTimingPlanDTO> calculateTimingPlan(Long routeId);

  ResponseEntity<RouteTimingPlanViewResponse> getTimingPlan(Long routeId);

  ResponseEntity<List<CompetitorEntryResponse>> listCompetitors(Long routeId);

  ResponseEntity<Void> deleteCompetitor(Long routeId, Long entryId);
}
