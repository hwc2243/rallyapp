package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import com.rallyapp.rallymaster.persistence.OrganizationPersistence;
import com.rallyapp.rallymaster.persistence.UserPersistence;
import com.rallyapp.rallymaster.service.base.BaseOrganizationMembershipServiceImpl;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrganizationMembershipServiceImpl
  extends BaseOrganizationMembershipServiceImpl<OrganizationMembershipDTO, OrganizationMembershipEntity,Long>
  implements OrganizationMembershipService
{
  
  @Autowired
  protected OrganizationMembershipMapper organizationMembershipMapper;

  @Autowired
  protected OrganizationMapper organizationMapper;

  @Autowired
  protected UserPersistence userPersistence;

  @Autowired
  protected OrganizationPersistence organizationPersistence;
  
  protected OrganizationMembershipEntity toEntity (OrganizationMembershipDTO dto) {
    return organizationMembershipMapper.toEntity(dto);
  }
  
  protected List<OrganizationMembershipEntity> toEntities (List<OrganizationMembershipDTO> dtos) {
    return organizationMembershipMapper.toEntities(dtos);
  }

  protected OrganizationMembershipDTO toDto (OrganizationMembershipEntity entity) {
    return organizationMembershipMapper.toDto(entity);
  }
  
  protected List<OrganizationMembershipDTO> toDtos (List<OrganizationMembershipEntity> entities) {
    return organizationMembershipMapper.toDtos(entities);
  }

  /** Returns the organizations for which the supplied user has a membership. */
  @Override
  @Transactional(readOnly = true)
  public List<OrganizationDTO> findOrganizationsByUser(UserDTO user) {
    if (user == null || user.getId() == null) {
      return List.of();
    }

    return organizationMembershipPersistence.findByUserId(user.getId()).stream()
        .map(OrganizationMembershipEntity::getOrganizationId)
        .map(organizationId -> organizationPersistence.findById(organizationId)
            .orElseThrow(() -> new IllegalStateException(
                "Membership references an organization that no longer exists: " + organizationId)))
        .map(organizationMapper::toDto)
        .toList();
  }

  @Override
  @Transactional
  public OrganizationMembershipDTO createMembership(
      UserDTO user, OrganizationDTO organization, OrganizationMembershipRole role) {
    if (user == null || user.getId() == null || organization == null || organization.getId() == null) {
      throw new IllegalArgumentException("A persisted user and organization are required for a membership.");
    }

    if (!userPersistence.existsById(user.getId())) {
      throw new IllegalArgumentException("User was not found.");
    }
    if (!organizationPersistence.existsById(organization.getId())) {
      throw new IllegalArgumentException("Organization was not found.");
    }

    OrganizationMembershipEntity membership = new OrganizationMembershipEntity();
    membership.setUserId(user.getId());
    membership.setOrganizationId(organization.getId());
    membership.setRole(role);

    return toDto(organizationMembershipPersistence.save(membership));
  }
}
