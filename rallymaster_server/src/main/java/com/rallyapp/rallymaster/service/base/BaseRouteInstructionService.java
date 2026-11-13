package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRouteInstructionDTO;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;

public interface BaseRouteInstructionService<D extends BaseRouteInstructionDTO, ID> extends EntityService<D, ID> {

	public List<D> findByRouteId (Long routeId);
}
