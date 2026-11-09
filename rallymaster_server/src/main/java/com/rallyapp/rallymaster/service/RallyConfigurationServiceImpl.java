package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.service.base.BaseRallyConfigurationServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RallyConfigurationServiceImpl
  extends BaseRallyConfigurationServiceImpl<RallyConfigurationDTO, RallyConfigurationEntity,Long>
  implements RallyConfigurationService
{
  
  @Autowired
  protected RallyConfigurationMapper rallyConfigurationMapper;

  @Autowired
  protected RallyPersistence rallyPersistence;
  
  protected RallyConfigurationEntity toEntity (RallyConfigurationDTO dto) {
    RallyConfigurationEntity entity = rallyConfigurationMapper.toEntity(dto);
    entity.setRally(dto.getRallyId() == null
        ? null
        : rallyPersistence.getReferenceById(dto.getRallyId()));
    return entity;
  }
  
  protected List<RallyConfigurationEntity> toEntities (List<RallyConfigurationDTO> dtos) {
    return rallyConfigurationMapper.toEntities(dtos);
  }

  protected RallyConfigurationDTO toDto (RallyConfigurationEntity entity) {
    return rallyConfigurationMapper.toDto(entity);
  }
  
  protected List<RallyConfigurationDTO> toDtos (List<RallyConfigurationEntity> entities) {
    return rallyConfigurationMapper.toDtos(entities);
  }

}
