package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.service.base.BaseCheckpointServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CheckpointServiceImpl
  extends BaseCheckpointServiceImpl<CheckpointDTO, CheckpointEntity,Long>
  implements CheckpointService
{
  
  @Autowired
  protected CheckpointMapper checkpointMapper;

  @Autowired
  protected RoutePersistence routePersistence;

  
  protected CheckpointEntity toEntity (CheckpointDTO dto) {
    CheckpointEntity entity = checkpointMapper.toEntity(dto);
    entity.setRoute(dto.getRouteId() == null
        ? null
        : routePersistence.getReferenceById(dto.getRouteId()));
    return entity;
  }
  
  protected List<CheckpointEntity> toEntities (List<CheckpointDTO> dtos) {
    return checkpointMapper.toEntities(dtos);
  }

  protected CheckpointDTO toDto (CheckpointEntity entity) {
    return checkpointMapper.toDto(entity);
  }
  
  protected List<CheckpointDTO> toDtos (List<CheckpointEntity> entities) {
    return checkpointMapper.toDtos(entities);
  }

}
