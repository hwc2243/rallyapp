package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
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
public interface UserMapper {

  @Named("userDefault")
  UserDTO toDto(UserEntity entity);

  @Named("userShallow")
  UserDTO toDtoShallow(UserEntity entity);


  @Named("organizationMembershipDefault")
  @Mapping(target = "userId", source = "user.id")
  OrganizationMembershipDTO organizationMembershipToDto(
      OrganizationMembershipEntity entity
  );



  @IterableMapping(qualifiedByName = "organizationMembershipDefault")
  Set<OrganizationMembershipDTO> membershipsToDtos(
      Set<OrganizationMembershipEntity> entities
  );


  @Mapping(target = "memberships", ignore = true)
  UserEntity toEntity(UserDTO dto);

  @IterableMapping(qualifiedByName = "userDefault")
  List<UserDTO> toDtos(List<UserEntity> entities);

  @IterableMapping(qualifiedByName = "userShallow")
  List<UserDTO> toDtosShallow(List<UserEntity> entities);

  List<UserEntity> toEntities(List<UserDTO> dtos);
}
