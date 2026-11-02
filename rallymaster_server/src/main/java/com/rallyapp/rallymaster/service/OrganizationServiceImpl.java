package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import com.rallyapp.rallymaster.service.base.BaseOrganizationServiceImpl;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrganizationServiceImpl
  extends BaseOrganizationServiceImpl<OrganizationDTO, OrganizationEntity,Long>
  implements OrganizationService
{
  
  @Autowired
  protected OrganizationMapper organizationMapper;

  @Autowired
  protected OrganizationMembershipService organizationMembershipService;

  @Autowired
  protected OrganizationMembershipMapper organizationMembershipMapper;
  
  protected OrganizationEntity toEntity (OrganizationDTO dto) {
    return organizationMapper.toEntity(dto);
  }
  
  protected List<OrganizationEntity> toEntities (List<OrganizationDTO> dtos) {
    return organizationMapper.toEntities(dtos);
  }

  protected OrganizationDTO toDto (OrganizationEntity entity) {
    return organizationMapper.toDto(entity);
  }
  
  protected List<OrganizationDTO> toDtos (List<OrganizationEntity> entities) {
    return organizationMapper.toDtos(entities);
  }

  @Override
  protected Collection<OrganizationMembershipDTO> toMembershipsDtos(
      OrganizationEntity entity) {
    if (entity.getMemberships() == null) {
      return List.of();
    }
    return organizationMembershipMapper.toDtos(new ArrayList<>(entity.getMemberships()));
  }

  /** Creates an organization and makes its creator an organization ADMIN. */
  @Override
  @Transactional(rollbackFor = Exception.class)
  public OrganizationDTO createOrganizationFor(
      UserDTO creator, OrganizationDTO organization) throws ServiceException {
    if (creator == null || creator.getId() == null) {
      throw new IllegalArgumentException("A persisted creator is required.");
    }

    OrganizationDTO createdOrganization = create(organization);
    organizationMembershipService.createMembership(
        creator, createdOrganization, OrganizationMembershipRole.ADMIN);
    return createdOrganization;
  }
}
