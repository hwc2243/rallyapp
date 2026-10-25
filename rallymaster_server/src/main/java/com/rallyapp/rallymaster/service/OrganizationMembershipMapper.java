package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import java.util.List;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface OrganizationMembershipMapper {

  @Named("organizationMembershipDefault")
  OrganizationMembershipDTO toDto(OrganizationMembershipEntity entity);

  @Named("organizationMembershipShallow")
  OrganizationMembershipDTO toDtoShallow(OrganizationMembershipEntity entity);

  OrganizationMembershipEntity toEntity(OrganizationMembershipDTO dto);

  @IterableMapping(qualifiedByName = "organizationMembershipDefault")
  List<OrganizationMembershipDTO> toDtos(List<OrganizationMembershipEntity> entities);

  @IterableMapping(qualifiedByName = "organizationMembershipShallow")
  List<OrganizationMembershipDTO> toDtosShallow(List<OrganizationMembershipEntity> entities);

  List<OrganizationMembershipEntity> toEntities(List<OrganizationMembershipDTO> dtos);
}
