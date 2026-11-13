package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.RouteEntity;
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
public interface RouteTimingPlanMapper {

  @Named("routeTimingPlanDefault")
  RouteTimingPlanDTO toDto(RouteTimingPlanEntity entity);

  @Named("routeTimingPlanShallow")
  RouteTimingPlanDTO toDtoShallow(RouteTimingPlanEntity entity);


  @Named("routeTimingPointDefault")
  RouteTimingPointDTO routeTimingPointToDto(
      RouteTimingPointEntity entity
  );



  @IterableMapping(qualifiedByName = "routeTimingPointDefault")
  List<RouteTimingPointDTO> pointsToDtos(
      List<RouteTimingPointEntity> entities
  );


  @Mapping(target = "route", ignore = true)
  @Mapping(target = "points", ignore = true)
  RouteTimingPlanEntity toEntity(RouteTimingPlanDTO dto);

  @IterableMapping(qualifiedByName = "routeTimingPlanDefault")
  List<RouteTimingPlanDTO> toDtos(List<RouteTimingPlanEntity> entities);

  @IterableMapping(qualifiedByName = "routeTimingPlanShallow")
  List<RouteTimingPlanDTO> toDtosShallow(List<RouteTimingPlanEntity> entities);

  List<RouteTimingPlanEntity> toEntities(List<RouteTimingPlanDTO> dtos);
}
