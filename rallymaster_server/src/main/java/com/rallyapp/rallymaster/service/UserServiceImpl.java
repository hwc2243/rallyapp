package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.service.base.BaseUserServiceImpl;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl
  extends BaseUserServiceImpl<UserDTO, UserEntity,Long>
  implements UserService
{
  
  @Autowired
  protected UserMapper userMapper;

  @Autowired
  protected OrganizationMembershipMapper organizationMembershipMapper;
  
  protected UserEntity toEntity (UserDTO dto) {
    return userMapper.toEntity(dto);
  }
  
  protected List<UserEntity> toEntities (List<UserDTO> dtos) {
    return userMapper.toEntities(dtos);
  }

  protected UserDTO toDto (UserEntity entity) {
    return userMapper.toDto(entity);
  }
  
  protected List<UserDTO> toDtos (List<UserEntity> entities) {
    return userMapper.toDtos(entities);
  }

  @Override
  protected Collection<OrganizationMembershipDTO> toMembershipsDtos(UserEntity entity) {
    if (entity.getMemberships() == null) {
      return List.of();
    }
    return organizationMembershipMapper.toDtos(new ArrayList<>(entity.getMemberships()));
  }
}
