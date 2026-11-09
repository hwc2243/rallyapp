package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRallyEntryDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;

public interface BaseRallyEntryService<D extends BaseRallyEntryDTO, ID> extends EntityService<D, ID> {

	public D fetchByOrganizationIdAndRallyIdAndCarNumber (Long rallyId, Long carNumber);

	public D fetchByOrganizationIdAndRallyIdAndPrimaryDeviceId (Long rallyId, String primaryDeviceId);
	public List<D> findByRouteId (Long routeId);
}
