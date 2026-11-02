package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
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
  
  protected RallyEntity toEntity (RallyDTO dto) {
    return rallyMapper.toEntity(dto);
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

  @Override
  protected Collection<RouteDTO> toRoutesDtos(RallyEntity entity) {
    if (entity.getRoutes() == null) {
      return List.of();
    }
    return rallyMapper.routesToDtos(entity.getRoutes());
  }
}
