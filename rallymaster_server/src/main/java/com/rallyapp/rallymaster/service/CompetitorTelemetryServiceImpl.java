package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.service.base.BaseCompetitorTelemetryServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CompetitorTelemetryServiceImpl
  extends BaseCompetitorTelemetryServiceImpl<CompetitorTelemetryDTO, CompetitorTelemetryEntity,Long>
  implements CompetitorTelemetryService
{
  
  @Autowired
  protected CompetitorTelemetryMapper competitorTelemetryMapper;

  
  protected CompetitorTelemetryEntity toEntity (CompetitorTelemetryDTO dto) {
    CompetitorTelemetryEntity entity = competitorTelemetryMapper.toEntity(dto);
    return entity;
  }
  
  protected List<CompetitorTelemetryEntity> toEntities (List<CompetitorTelemetryDTO> dtos) {
    return competitorTelemetryMapper.toEntities(dtos);
  }

  protected CompetitorTelemetryDTO toDto (CompetitorTelemetryEntity entity) {
    return competitorTelemetryMapper.toDto(entity);
  }
  
  protected List<CompetitorTelemetryDTO> toDtos (List<CompetitorTelemetryEntity> entities) {
    return competitorTelemetryMapper.toDtos(entities);
  }

  protected Collection<CompetitorTelemetryDataDTO> toDataDtos (CompetitorTelemetryEntity entity) {
    return competitorTelemetryMapper.dataToDtos(entity.getData());
  }
}
