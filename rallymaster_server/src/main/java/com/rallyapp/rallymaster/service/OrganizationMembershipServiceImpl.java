package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.persistence.OrganizationPersistence;
import com.rallyapp.rallymaster.persistence.UserPersistence;
import com.rallyapp.rallymaster.service.base.BaseOrganizationMembershipServiceImpl;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import java.util.Collection;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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
    OrganizationMembershipEntity entity = organizationMembershipMapper.toEntity(dto);
    entity.setUser(dto.getUserId() == null
        ? null
        : userPersistence.getReferenceById(dto.getUserId()));
    entity.setOrganization(dto.getOrganizationId() == null
        ? null
        : organizationPersistence.getReferenceById(dto.getOrganizationId()));
    return entity;
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

  @Override
  @Transactional(readOnly = true)
  public List<OrganizationDTO> findOrganizationByUser(Long userId) {
    return organizationMembershipPersistence.findByUserId(userId).stream()
        .map(OrganizationMembershipEntity::getOrganization)
        .filter(organization -> organization != null)
        .map(organizationMapper::toDto)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<OrganizationDTO> findOrganizationsByUser(UserDTO user) {
    if (user == null || user.getId() == null) {
      return List.of();
    }
    return findOrganizationByUser(user.getId());
  }

  @Override
  @Transactional
  public OrganizationMembershipDTO createMembership(
      UserDTO user, OrganizationDTO organization, OrganizationMembershipRole role) {
    if (user == null || user.getId() == null ||
        organization == null || organization.getId() == null) {
      throw new IllegalArgumentException(
          "A persisted user and organization are required for a membership.");
    }
    if (!userPersistence.existsById(user.getId())) {
      throw new IllegalArgumentException("User was not found.");
    }
    if (!organizationPersistence.existsById(organization.getId())) {
      throw new IllegalArgumentException("Organization was not found.");
    }

    OrganizationMembershipEntity membership = new OrganizationMembershipEntity();
    membership.setUser(userPersistence.getReferenceById(user.getId()));
    membership.setOrganization(
        organizationPersistence.getReferenceById(organization.getId()));
    membership.setRole(role);
    return toDto(organizationMembershipPersistence.save(membership));
  }

}
