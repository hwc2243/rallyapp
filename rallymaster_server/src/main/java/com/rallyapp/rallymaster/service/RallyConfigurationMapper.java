package com.rallyapp.rallymaster.service;



import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import java.util.List;
import java.util.Set;
import org.mapstruct.IterableMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.SubclassMapping;

@Mapper(componentModel = "spring")
public interface RallyConfigurationMapper {

  @Named("rallyConfigurationDefault")
  @Mapping(target = "rallyId", source = "rally.id")
  RallyConfigurationDTO toDto(RallyConfigurationEntity entity);

  @Named("rallyConfigurationShallow")
  RallyConfigurationDTO toDtoShallow(RallyConfigurationEntity entity);



  @Mapping(target = "rally", ignore = true)
  RallyConfigurationEntity toEntity(RallyConfigurationDTO dto);

  @IterableMapping(qualifiedByName = "rallyConfigurationDefault")
  List<RallyConfigurationDTO> toDtos(List<RallyConfigurationEntity> entities);

  @IterableMapping(qualifiedByName = "rallyConfigurationShallow")
  List<RallyConfigurationDTO> toDtosShallow(List<RallyConfigurationEntity> entities);

  List<RallyConfigurationEntity> toEntities(List<RallyConfigurationDTO> dtos);
}
