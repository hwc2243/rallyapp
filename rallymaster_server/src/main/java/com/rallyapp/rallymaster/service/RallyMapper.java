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
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface RallyMapper {

  @Named("rallyDefault")
  @Mapping(target = "userId", source = "user.id")
  RallyDTO toDto(RallyEntity entity);

  @Named("rallyShallow")
  RallyDTO toDtoShallow(RallyEntity entity);


  @Named("routeDefault")
  @Mapping(target = "rallyId", source = "rally.id")
  RouteDTO routeToDto(
      RouteEntity entity
  );



  @IterableMapping(qualifiedByName = "routeDefault")
  List<RouteDTO> routesToDtos(
      List<RouteEntity> entities
  );


  @Mapping(target = "user", ignore = true)
  @Mapping(target = "routes", ignore = true)
  RallyEntity toEntity(RallyDTO dto);

  @IterableMapping(qualifiedByName = "rallyDefault")
  List<RallyDTO> toDtos(List<RallyEntity> entities);

  @IterableMapping(qualifiedByName = "rallyShallow")
  List<RallyDTO> toDtosShallow(List<RallyEntity> entities);

  List<RallyEntity> toEntities(List<RallyDTO> dtos);
}
