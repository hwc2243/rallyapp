package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseOrganizationDTO;
import java.util.List;

public interface BaseOrganizationService<D extends BaseOrganizationDTO, ID> extends EntityService<D, ID> {

	public D fetchByName (String name);
}
