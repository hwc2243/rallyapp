package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.service.base.BaseUserServiceImpl;
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
}