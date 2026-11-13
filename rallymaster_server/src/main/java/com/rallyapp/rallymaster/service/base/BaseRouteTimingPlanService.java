package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.Collection;
import java.util.List;

public interface BaseRouteTimingPlanService<D extends BaseRouteTimingPlanDTO, ID> extends EntityService<D, ID> {

	public D fetchByOrganizationIdAndRouteId (Long routeId);
	public Collection<RouteTimingPointDTO> getPoints (ID id) throws ServiceException;
}
