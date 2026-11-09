package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
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
public interface RallyEntryMapper {

  @Named("rallyEntryDefault")
  @Mapping(target = "rallyId", source = "rally.id")
  @Mapping(target = "routeId", source = "route.id")
  RallyEntryDTO toDto(RallyEntryEntity entity);

  @Named("rallyEntryShallow")
  RallyEntryDTO toDtoShallow(RallyEntryEntity entity);



  @Mapping(target = "rally", ignore = true)
  @Mapping(target = "route", ignore = true)
  RallyEntryEntity toEntity(RallyEntryDTO dto);

  @IterableMapping(qualifiedByName = "rallyEntryDefault")
  List<RallyEntryDTO> toDtos(List<RallyEntryEntity> entities);

  @IterableMapping(qualifiedByName = "rallyEntryShallow")
  List<RallyEntryDTO> toDtosShallow(List<RallyEntryEntity> entities);

  List<RallyEntryEntity> toEntities(List<RallyEntryDTO> dtos);
}
