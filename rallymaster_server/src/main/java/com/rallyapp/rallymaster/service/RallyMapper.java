package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface RallyMapper {

  @Named("rallyDefault")
  @Mapping(target = "routes", ignore = true)
  RallyDTO toDto(RallyEntity entity);

  @Named("rallyShallow")
  @Mapping(
      target = "routes",
      source = "routes",
      qualifiedByName = "routeDefault"
  )
  RallyDTO toDtoShallow(RallyEntity entity);


  @Named("routeDefault")
  @Mapping(target = "items", ignore = true)
  RouteDTO routeToDto(
      RouteEntity entity
  );


  @IterableMapping(qualifiedByName = "routeDefault")
  List<RouteDTO> routesToDtos(
      List<RouteEntity> entities
  );


  @Mapping(target = "routes", ignore = true)
  RallyEntity toEntity(RallyDTO dto);

  @IterableMapping(qualifiedByName = "rallyDefault")
  List<RallyDTO> toDtos(List<RallyEntity> entities);

  @IterableMapping(qualifiedByName = "rallyShallow")
  List<RallyDTO> toDtosShallow(List<RallyEntity> entities);

  List<RallyEntity> toEntities(List<RallyDTO> dtos);
}
