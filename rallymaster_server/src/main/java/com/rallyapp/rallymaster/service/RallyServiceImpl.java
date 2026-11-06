package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.persistence.UserPersistence;
import com.rallyapp.rallymaster.service.base.BaseRallyServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RallyServiceImpl
  extends BaseRallyServiceImpl<RallyDTO, RallyEntity,Long>
  implements RallyService
{
  
  @Autowired
  protected RallyMapper rallyMapper;

  @Autowired
  protected UserPersistence userPersistence;
  
  protected RallyEntity toEntity (RallyDTO dto) {
    RallyEntity entity = rallyMapper.toEntity(dto);
    entity.setUser(dto.getUserId() == null
        ? null
        : userPersistence.getReferenceById(dto.getUserId()));
    return entity;
  }
  
  protected List<RallyEntity> toEntities (List<RallyDTO> dtos) {
    return rallyMapper.toEntities(dtos);
  }

  protected RallyDTO toDto (RallyEntity entity) {
    return rallyMapper.toDto(entity);
  }
  
  protected List<RallyDTO> toDtos (List<RallyEntity> entities) {
    return rallyMapper.toDtos(entities);
  }

  protected Collection<RouteDTO> toRoutesDtos (RallyEntity entity) {
    return rallyMapper.routesToDtos(entity.getRoutes());
  }
}
