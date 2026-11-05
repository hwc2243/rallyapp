package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface RouteMapper {

  @Named("routeDefault")
  @Mapping(target = "rallyId", source = "rally.id")
  RouteDTO toDto(RouteEntity entity);

  @Named("routeShallow")
  RouteDTO toDtoShallow(RouteEntity entity);


  @Named("routeItemDefault")
  @Mapping(target = "routeId", source = "route.id")
  @SubclassMapping(source = CheckpointEntity.class, target = CheckpointDTO.class)
  @SubclassMapping(source = RouteInstructionEntity.class, target = RouteInstructionDTO.class)
  RouteItemDTO routeItemToDto(
      RouteItemEntity entity
  );

  @Mapping(target = "routeId", source = "route.id")
  CheckpointDTO checkpointToDto(CheckpointEntity entity);
  @Mapping(target = "routeId", source = "route.id")
  RouteInstructionDTO routeInstructionToDto(RouteInstructionEntity entity);


  @IterableMapping(qualifiedByName = "routeItemDefault")
  List<RouteItemDTO> itemsToDtos(
      List<RouteItemEntity> entities
  );


  @Mapping(target = "rally", ignore = true)
  @Mapping(target = "items", ignore = true)
  RouteEntity toEntity(RouteDTO dto);

  @IterableMapping(qualifiedByName = "routeDefault")
  List<RouteDTO> toDtos(List<RouteEntity> entities);

  @IterableMapping(qualifiedByName = "routeShallow")
  List<RouteDTO> toDtosShallow(List<RouteEntity> entities);

  List<RouteEntity> toEntities(List<RouteDTO> dtos);
}
