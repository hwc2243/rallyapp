package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface CheckpointMapper {

  @Named("checkpointDefault")
  @Mapping(target = "routeId", source = "route.id")
  CheckpointDTO toDto(CheckpointEntity entity);

  @Named("checkpointShallow")
  CheckpointDTO toDtoShallow(CheckpointEntity entity);



  @Mapping(target = "route", ignore = true)
  CheckpointEntity toEntity(CheckpointDTO dto);

  @IterableMapping(qualifiedByName = "checkpointDefault")
  List<CheckpointDTO> toDtos(List<CheckpointEntity> entities);

  @IterableMapping(qualifiedByName = "checkpointShallow")
  List<CheckpointDTO> toDtosShallow(List<CheckpointEntity> entities);

  List<CheckpointEntity> toEntities(List<CheckpointDTO> dtos);
}
