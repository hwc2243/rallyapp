package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.UserEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface UserMapper {

  @Named("userDefault")
  @Mapping(target = "memberships", ignore = true)
  UserDTO toDto(UserEntity entity);

  @Named("userShallow")
  @Mapping(target = "memberships", ignore = true)
  UserDTO toDtoShallow(UserEntity entity);



  @Mapping(target = "memberships", ignore = true)
  UserEntity toEntity(UserDTO dto);

  @IterableMapping(qualifiedByName = "userDefault")
  List<UserDTO> toDtos(List<UserEntity> entities);

  @IterableMapping(qualifiedByName = "userShallow")
  List<UserDTO> toDtosShallow(List<UserEntity> entities);

  List<UserEntity> toEntities(List<UserDTO> dtos);
}
