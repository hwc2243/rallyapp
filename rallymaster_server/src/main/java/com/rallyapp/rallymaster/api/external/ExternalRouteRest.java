package com.rallyapp.rallymaster.api.external;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRest;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import org.springframework.http.ResponseEntity;

public interface ExternalRouteRest extends BaseExternalRouteRest
{
  ResponseEntity<RoutePlanDTO> saveRoutePlan(Long routeId, RoutePlanDTO plan);
}
