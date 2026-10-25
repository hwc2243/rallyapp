package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import java.util.List;
import com.rallyapp.rallymaster.service.base.BaseOrganizationMembershipService;

public interface OrganizationMembershipService extends BaseOrganizationMembershipService<OrganizationMembershipDTO,Long>
{
	List<OrganizationDTO> findOrganizationsByUser(UserDTO user);

	OrganizationMembershipDTO createMembership(
			UserDTO user, OrganizationDTO organization, OrganizationMembershipRole role);
}
