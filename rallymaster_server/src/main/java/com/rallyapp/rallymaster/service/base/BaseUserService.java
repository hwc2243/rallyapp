package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseUserDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.Collection;
import java.util.List;

public interface BaseUserService<D extends BaseUserDTO, ID> extends EntityService<D, ID> {

	public D fetchByEmailAddress (String emailAddress);
	public Collection<OrganizationMembershipDTO> getMemberships (ID id) throws ServiceException;
}
