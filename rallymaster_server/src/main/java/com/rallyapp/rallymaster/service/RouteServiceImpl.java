package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.entity.RouteEntity;
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
  
  protected RouteEntity toEntity (RouteDTO dto) {
    return routeMapper.toEntity(dto);
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

  @Override
  protected Collection<RouteItemDTO> toItemsDtos(RouteEntity entity) {
    if (entity.getItems() == null) {
      return List.of();
    }
    return routeMapper.itemsToDtos(entity.getItems());
  }
}
