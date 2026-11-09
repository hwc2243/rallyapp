package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.service.base.BaseRallyEntryServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RallyEntryServiceImpl
  extends BaseRallyEntryServiceImpl<RallyEntryDTO, RallyEntryEntity,Long>
  implements RallyEntryService
{
  
  @Autowired
  protected RallyEntryMapper rallyEntryMapper;

  @Autowired
  protected RallyPersistence rallyPersistence;
  @Autowired
  protected RoutePersistence routePersistence;
  
  protected RallyEntryEntity toEntity (RallyEntryDTO dto) {
    RallyEntryEntity entity = rallyEntryMapper.toEntity(dto);
    entity.setRally(dto.getRallyId() == null
        ? null
        : rallyPersistence.getReferenceById(dto.getRallyId()));
    entity.setRoute(dto.getRouteId() == null
        ? null
        : routePersistence.getReferenceById(dto.getRouteId()));
    return entity;
  }
  
  protected List<RallyEntryEntity> toEntities (List<RallyEntryDTO> dtos) {
    return rallyEntryMapper.toEntities(dtos);
  }

  protected RallyEntryDTO toDto (RallyEntryEntity entity) {
    return rallyEntryMapper.toDto(entity);
  }
  
  protected List<RallyEntryDTO> toDtos (List<RallyEntryEntity> entities) {
    return rallyEntryMapper.toDtos(entities);
  }

}
