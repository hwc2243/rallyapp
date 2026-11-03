package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import com.rallyapp.rallymaster.service.base.BaseOrganizationMembershipService;
import java.util.List;

public interface OrganizationMembershipService extends BaseOrganizationMembershipService<OrganizationMembershipDTO,Long>
{
  /** Returns every organization to which the supplied user belongs. */
  List<OrganizationDTO> findOrganizationByUser(Long userId);

  List<OrganizationDTO> findOrganizationsByUser(UserDTO user);

  OrganizationMembershipDTO createMembership(
      UserDTO user, OrganizationDTO organization, OrganizationMembershipRole role);
}
