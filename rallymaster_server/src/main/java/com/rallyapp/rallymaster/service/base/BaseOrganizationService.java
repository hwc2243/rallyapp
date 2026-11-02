package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseOrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.Collection;
import java.util.List;

public interface BaseOrganizationService<D extends BaseOrganizationDTO, ID> extends EntityService<D, ID> {

	public D fetchByName (String name);
	public Collection<OrganizationMembershipDTO> getMemberships (ID id) throws ServiceException;
}
