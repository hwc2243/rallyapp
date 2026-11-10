package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface CompetitorTelemetryMapper {

  @Named("competitorTelemetryDefault")
  CompetitorTelemetryDTO toDto(CompetitorTelemetryEntity entity);

  @Named("competitorTelemetryShallow")
  CompetitorTelemetryDTO toDtoShallow(CompetitorTelemetryEntity entity);


  @Named("competitorTelemetryDataDefault")
  CompetitorTelemetryDataDTO competitorTelemetryDataToDto(
      CompetitorTelemetryDataEntity entity
  );



  @IterableMapping(qualifiedByName = "competitorTelemetryDataDefault")
  List<CompetitorTelemetryDataDTO> dataToDtos(
      List<CompetitorTelemetryDataEntity> entities
  );


  @Mapping(target = "rallyEntry", ignore = true)
  @Mapping(target = "route", ignore = true)
  @Mapping(target = "checkpoint", ignore = true)
  @Mapping(target = "data", ignore = true)
  CompetitorTelemetryEntity toEntity(CompetitorTelemetryDTO dto);

  @IterableMapping(qualifiedByName = "competitorTelemetryDefault")
  List<CompetitorTelemetryDTO> toDtos(List<CompetitorTelemetryEntity> entities);

  @IterableMapping(qualifiedByName = "competitorTelemetryShallow")
  List<CompetitorTelemetryDTO> toDtosShallow(List<CompetitorTelemetryEntity> entities);

  List<CompetitorTelemetryEntity> toEntities(List<CompetitorTelemetryDTO> dtos);
}
