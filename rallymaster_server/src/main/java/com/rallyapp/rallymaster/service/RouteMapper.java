package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface RouteMapper {

  @Named("routeDefault")
  @Mapping(target = "items", ignore = true)
  RouteDTO toDto(RouteEntity entity);

  @Named("routeShallow")
  @Mapping(
      target = "items",
      source = "items",
      qualifiedByName = "routeItemDefault"
  )
  RouteDTO toDtoShallow(RouteEntity entity);


  @Named("routeItemDefault")
  RouteItemDTO routeItemToDto(
      RouteItemEntity entity
  );


  @IterableMapping(qualifiedByName = "routeItemDefault")
  List<RouteItemDTO> itemsToDtos(
      List<RouteItemEntity> entities
  );


  @Mapping(target = "items", ignore = true)
  RouteEntity toEntity(RouteDTO dto);

  @IterableMapping(qualifiedByName = "routeDefault")
  List<RouteDTO> toDtos(List<RouteEntity> entities);

  @IterableMapping(qualifiedByName = "routeShallow")
  List<RouteDTO> toDtosShallow(List<RouteEntity> entities);

  List<RouteEntity> toEntities(List<RouteDTO> dtos);
}
