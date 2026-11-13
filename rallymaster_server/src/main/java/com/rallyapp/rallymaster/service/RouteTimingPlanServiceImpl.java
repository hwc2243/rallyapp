package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.service.base.BaseRouteTimingPlanServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RouteTimingPlanServiceImpl
  extends BaseRouteTimingPlanServiceImpl<RouteTimingPlanDTO, RouteTimingPlanEntity,Long>
  implements RouteTimingPlanService
{
  
  @Autowired
  protected RouteTimingPlanMapper routeTimingPlanMapper;

  
  protected RouteTimingPlanEntity toEntity (RouteTimingPlanDTO dto) {
    RouteTimingPlanEntity entity = routeTimingPlanMapper.toEntity(dto);
    return entity;
  }
  
  protected List<RouteTimingPlanEntity> toEntities (List<RouteTimingPlanDTO> dtos) {
    return routeTimingPlanMapper.toEntities(dtos);
  }

  protected RouteTimingPlanDTO toDto (RouteTimingPlanEntity entity) {
    return routeTimingPlanMapper.toDto(entity);
  }
  
  protected List<RouteTimingPlanDTO> toDtos (List<RouteTimingPlanEntity> entities) {
    return routeTimingPlanMapper.toDtos(entities);
  }

  protected Collection<RouteTimingPointDTO> toPointsDtos (RouteTimingPlanEntity entity) {
    return routeTimingPlanMapper.pointsToDtos(entity.getPoints());
  }
}
