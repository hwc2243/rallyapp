package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.service.base.BaseRouteService;
import java.util.List;

public interface RouteService extends BaseRouteService<RouteDTO,Long>
{
	List<RouteDTO> findByRallyId(Long rallyId);

	RoutePlanDTO savePlan(Long routeId, RoutePlanDTO plan) throws ServiceException;
}
