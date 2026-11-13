package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface RouteTimingPointMapper {

  @Named("routeTimingPointDefault")
  RouteTimingPointDTO toDto(RouteTimingPointEntity entity);

  @Named("routeTimingPointShallow")
  RouteTimingPointDTO toDtoShallow(RouteTimingPointEntity entity);



  @Mapping(target = "routeTimingPlan", ignore = true)
  @Mapping(target = "routeItem", ignore = true)
  RouteTimingPointEntity toEntity(RouteTimingPointDTO dto);

  @IterableMapping(qualifiedByName = "routeTimingPointDefault")
  List<RouteTimingPointDTO> toDtos(List<RouteTimingPointEntity> entities);

  @IterableMapping(qualifiedByName = "routeTimingPointShallow")
  List<RouteTimingPointDTO> toDtosShallow(List<RouteTimingPointEntity> entities);

  List<RouteTimingPointEntity> toEntities(List<RouteTimingPointDTO> dtos);
}
