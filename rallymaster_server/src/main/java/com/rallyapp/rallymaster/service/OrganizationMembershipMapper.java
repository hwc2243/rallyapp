package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface OrganizationMembershipMapper {

  @Named("organizationMembershipDefault")
  @Mapping(target = "userId", source = "user.id")
  OrganizationMembershipDTO toDto(OrganizationMembershipEntity entity);

  @Named("organizationMembershipShallow")
  OrganizationMembershipDTO toDtoShallow(OrganizationMembershipEntity entity);



  @Mapping(target = "user", ignore = true)
  OrganizationMembershipEntity toEntity(OrganizationMembershipDTO dto);

  @IterableMapping(qualifiedByName = "organizationMembershipDefault")
  List<OrganizationMembershipDTO> toDtos(List<OrganizationMembershipEntity> entities);

  @IterableMapping(qualifiedByName = "organizationMembershipShallow")
  List<OrganizationMembershipDTO> toDtosShallow(List<OrganizationMembershipEntity> entities);

  List<OrganizationMembershipEntity> toEntities(List<OrganizationMembershipDTO> dtos);
}
