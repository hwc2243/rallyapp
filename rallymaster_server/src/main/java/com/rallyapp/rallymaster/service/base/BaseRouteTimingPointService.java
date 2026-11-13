package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPointDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;

public interface BaseRouteTimingPointService<D extends BaseRouteTimingPointDTO, ID> extends EntityService<D, ID> {

	public D fetchByOrganizationIdAndRouteTimingPlanIdAndRouteItemId (Long routeTimingPlanId, Long routeItemId);
}
