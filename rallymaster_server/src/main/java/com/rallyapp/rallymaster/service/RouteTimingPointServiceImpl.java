package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.service.base.BaseRouteTimingPointServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RouteTimingPointServiceImpl
  extends BaseRouteTimingPointServiceImpl<RouteTimingPointDTO, RouteTimingPointEntity,Long>
  implements RouteTimingPointService
{
  
  @Autowired
  protected RouteTimingPointMapper routeTimingPointMapper;

  
  protected RouteTimingPointEntity toEntity (RouteTimingPointDTO dto) {
    RouteTimingPointEntity entity = routeTimingPointMapper.toEntity(dto);
    return entity;
  }
  
  protected List<RouteTimingPointEntity> toEntities (List<RouteTimingPointDTO> dtos) {
    return routeTimingPointMapper.toEntities(dtos);
  }

  protected RouteTimingPointDTO toDto (RouteTimingPointEntity entity) {
    return routeTimingPointMapper.toDto(entity);
  }
  
  protected List<RouteTimingPointDTO> toDtos (List<RouteTimingPointEntity> entities) {
    return routeTimingPointMapper.toDtos(entities);
  }

}
