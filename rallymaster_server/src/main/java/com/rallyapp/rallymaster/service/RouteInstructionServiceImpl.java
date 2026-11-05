package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.service.base.BaseRouteInstructionServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RouteInstructionServiceImpl
  extends BaseRouteInstructionServiceImpl<RouteInstructionDTO, RouteInstructionEntity,Long>
  implements RouteInstructionService
{
  
  @Autowired
  protected RouteInstructionMapper routeInstructionMapper;

  @Autowired
  protected RoutePersistence routePersistence;

  
  protected RouteInstructionEntity toEntity (RouteInstructionDTO dto) {
    RouteInstructionEntity entity = routeInstructionMapper.toEntity(dto);
    entity.setRoute(dto.getRouteId() == null
        ? null
        : routePersistence.getReferenceById(dto.getRouteId()));
    return entity;
  }
  
  protected List<RouteInstructionEntity> toEntities (List<RouteInstructionDTO> dtos) {
    return routeInstructionMapper.toEntities(dtos);
  }

  protected RouteInstructionDTO toDto (RouteInstructionEntity entity) {
    return routeInstructionMapper.toDto(entity);
  }
  
  protected List<RouteInstructionDTO> toDtos (List<RouteInstructionEntity> entities) {
    return routeInstructionMapper.toDtos(entities);
  }

}
