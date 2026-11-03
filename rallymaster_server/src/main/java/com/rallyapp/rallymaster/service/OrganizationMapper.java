package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface OrganizationMapper {

  @Named("organizationDefault")
  OrganizationDTO toDto(OrganizationEntity entity);

  @Named("organizationShallow")
  OrganizationDTO toDtoShallow(OrganizationEntity entity);


  @Named("organizationMembershipDefault")
  OrganizationMembershipDTO organizationMembershipToDto(
      OrganizationMembershipEntity entity
  );


  @IterableMapping(qualifiedByName = "organizationMembershipDefault")
  Set<OrganizationMembershipDTO> organizationMembershipsToDtos(
      Set<OrganizationMembershipEntity> entities
  );


  OrganizationEntity toEntity(OrganizationDTO dto);

  @IterableMapping(qualifiedByName = "organizationDefault")
  List<OrganizationDTO> toDtos(List<OrganizationEntity> entities);

  @IterableMapping(qualifiedByName = "organizationShallow")
  List<OrganizationDTO> toDtosShallow(List<OrganizationEntity> entities);

  List<OrganizationEntity> toEntities(List<OrganizationDTO> dtos);
}
