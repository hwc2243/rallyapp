package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.Collection;
import java.util.List;

public interface BaseRouteService<D extends BaseRouteDTO, ID> extends EntityService<D, ID> {
	public List<D> findByRallyId (Long rallyId);
	public Collection<RouteItemDTO> getItems (ID id) throws ServiceException;
}
