package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

public interface BaseRallyService<D extends BaseRallyDTO, ID> extends EntityService<D, ID> {
	public Collection<RouteDTO> getRoutes (ID id) throws ServiceException;
}
