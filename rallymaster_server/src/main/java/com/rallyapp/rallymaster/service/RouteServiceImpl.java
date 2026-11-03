package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.service.base.BaseRouteServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RouteServiceImpl
  extends BaseRouteServiceImpl<RouteDTO, RouteEntity,Long>
  implements RouteService
{
  
  @Autowired
  protected RouteMapper routeMapper;

  @Autowired
  protected RallyPersistence rallyPersistence;
  
  protected RouteEntity toEntity (RouteDTO dto) {
    RouteEntity entity = routeMapper.toEntity(dto);
    entity.setRally(dto.getRallyId() == null
        ? null
        : rallyPersistence.getReferenceById(dto.getRallyId()));
    return entity;
  }
  
  protected List<RouteEntity> toEntities (List<RouteDTO> dtos) {
    return routeMapper.toEntities(dtos);
  }

  protected RouteDTO toDto (RouteEntity entity) {
    return routeMapper.toDto(entity);
  }
  
  protected List<RouteDTO> toDtos (List<RouteEntity> entities) {
    return routeMapper.toDtos(entities);
  }

  protected Collection<RouteItemDTO> toItemsDtos (RouteEntity entity) {
    return routeMapper.itemsToDtos(entity.getItems());
  }
}
