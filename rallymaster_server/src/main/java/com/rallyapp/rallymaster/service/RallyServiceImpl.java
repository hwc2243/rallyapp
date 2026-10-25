package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.service.base.BaseRallyServiceImpl;
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
}