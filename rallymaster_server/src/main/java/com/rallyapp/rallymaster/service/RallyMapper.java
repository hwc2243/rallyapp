package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface RallyMapper {

  @Named("rallyDefault")
  RallyDTO toDto(RallyEntity entity);

  @Named("rallyShallow")
  RallyDTO toDtoShallow(RallyEntity entity);



  RallyEntity toEntity(RallyDTO dto);

  @IterableMapping(qualifiedByName = "rallyDefault")
  List<RallyDTO> toDtos(List<RallyEntity> entities);

  @IterableMapping(qualifiedByName = "rallyShallow")
  List<RallyDTO> toDtosShallow(List<RallyEntity> entities);

  List<RallyEntity> toEntities(List<RallyDTO> dtos);
}