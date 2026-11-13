package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRallyConfigurationDTO;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;

public interface BaseRallyConfigurationService<D extends BaseRallyConfigurationDTO, ID> extends EntityService<D, ID> {

	public D fetchByOrganizationIdAndRallyId (Long rallyId);
}
