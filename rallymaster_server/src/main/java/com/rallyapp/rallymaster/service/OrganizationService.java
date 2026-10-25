package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.base.BaseOrganizationService;

public interface OrganizationService extends BaseOrganizationService<OrganizationDTO,Long>
{
	OrganizationDTO createOrganizationFor(UserDTO creator, OrganizationDTO organization)
			throws ServiceException;
}
