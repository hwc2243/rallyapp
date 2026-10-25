package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface OrganizationMapper {

  @Named("organizationDefault")
  @Mapping(target = "memberships", ignore = true)
  OrganizationDTO toDto(OrganizationEntity entity);

  @Named("organizationShallow")
  @Mapping(target = "memberships", ignore = true)
  OrganizationDTO toDtoShallow(OrganizationEntity entity);



  @Mapping(target = "memberships", ignore = true)
  OrganizationEntity toEntity(OrganizationDTO dto);

  @IterableMapping(qualifiedByName = "organizationDefault")
  List<OrganizationDTO> toDtos(List<OrganizationEntity> entities);

  @IterableMapping(qualifiedByName = "organizationShallow")
  List<OrganizationDTO> toDtosShallow(List<OrganizationEntity> entities);

  List<OrganizationEntity> toEntities(List<OrganizationDTO> dtos);
}
