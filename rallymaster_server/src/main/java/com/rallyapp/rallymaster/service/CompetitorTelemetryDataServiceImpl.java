package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.service.base.BaseCompetitorTelemetryDataServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CompetitorTelemetryDataServiceImpl
  extends BaseCompetitorTelemetryDataServiceImpl<CompetitorTelemetryDataDTO, CompetitorTelemetryDataEntity,Long>
  implements CompetitorTelemetryDataService
{
  
  @Autowired
  protected CompetitorTelemetryDataMapper competitorTelemetryDataMapper;

  
  protected CompetitorTelemetryDataEntity toEntity (CompetitorTelemetryDataDTO dto) {
    CompetitorTelemetryDataEntity entity = competitorTelemetryDataMapper.toEntity(dto);
    return entity;
  }
  
  protected List<CompetitorTelemetryDataEntity> toEntities (List<CompetitorTelemetryDataDTO> dtos) {
    return competitorTelemetryDataMapper.toEntities(dtos);
  }

  protected CompetitorTelemetryDataDTO toDto (CompetitorTelemetryDataEntity entity) {
    return competitorTelemetryDataMapper.toDto(entity);
  }
  
  protected List<CompetitorTelemetryDataDTO> toDtos (List<CompetitorTelemetryDataEntity> entities) {
    return competitorTelemetryDataMapper.toDtos(entities);
  }

}
