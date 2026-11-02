package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface RouteInstructionMapper {

  @Named("routeInstructionDefault")
  RouteInstructionDTO toDto(RouteInstructionEntity entity);

  @Named("routeInstructionShallow")
  RouteInstructionDTO toDtoShallow(RouteInstructionEntity entity);



  RouteInstructionEntity toEntity(RouteInstructionDTO dto);

  @IterableMapping(qualifiedByName = "routeInstructionDefault")
  List<RouteInstructionDTO> toDtos(List<RouteInstructionEntity> entities);

  @IterableMapping(qualifiedByName = "routeInstructionShallow")
  List<RouteInstructionDTO> toDtosShallow(List<RouteInstructionEntity> entities);

  List<RouteInstructionEntity> toEntities(List<RouteInstructionDTO> dtos);
}
