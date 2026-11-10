package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface CompetitorTelemetryDataMapper {

  @Named("competitorTelemetryDataDefault")
  CompetitorTelemetryDataDTO toDto(CompetitorTelemetryDataEntity entity);

  @Named("competitorTelemetryDataShallow")
  CompetitorTelemetryDataDTO toDtoShallow(CompetitorTelemetryDataEntity entity);



  @Mapping(target = "competitorTelemetry", ignore = true)
  CompetitorTelemetryDataEntity toEntity(CompetitorTelemetryDataDTO dto);

  @IterableMapping(qualifiedByName = "competitorTelemetryDataDefault")
  List<CompetitorTelemetryDataDTO> toDtos(List<CompetitorTelemetryDataEntity> entities);

  @IterableMapping(qualifiedByName = "competitorTelemetryDataShallow")
  List<CompetitorTelemetryDataDTO> toDtosShallow(List<CompetitorTelemetryDataEntity> entities);

  List<CompetitorTelemetryDataEntity> toEntities(List<CompetitorTelemetryDataDTO> dtos);
}
