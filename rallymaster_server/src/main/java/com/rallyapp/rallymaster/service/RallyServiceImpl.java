package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.persistence.UserPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.service.base.BaseRallyServiceImpl;
import java.util.Collection;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RallyServiceImpl
  extends BaseRallyServiceImpl<RallyDTO, RallyEntity,Long>
  implements RallyService
{
  
  @Autowired
  protected RallyMapper rallyMapper;

  @Autowired
  protected UserPersistence userPersistence;

  @Autowired protected RallyPersistence rallyPersistence;
  @Autowired protected RallyConfigurationPersistence rallyConfigurationPersistence;
  @Autowired protected RouteService routeService;
  
  protected RallyEntity toEntity (RallyDTO dto) {
    RallyEntity entity = rallyMapper.toEntity(dto);
    entity.setUser(dto.getUserId() == null
        ? null
        : userPersistence.getReferenceById(dto.getUserId()));
    return entity;
  }
  
  protected List<RallyEntity> toEntities (List<RallyDTO> dtos) {
    return rallyMapper.toEntities(dtos);
  }

  protected RallyDTO toDto (RallyEntity entity) {
    return rallyMapper.toDto(entity);
  }
  
  protected List<RallyDTO> toDtos (List<RallyEntity> entities) {
    return rallyMapper.toDtos(entities);
  }

  protected Collection<RouteDTO> toRoutesDtos (RallyEntity entity) {
    return rallyMapper.routesToDtos(entity.getRoutes());
  }

  /** Deletes an un-published rally and all of its planning routes. */
  @Override
  @Transactional
  public void delete(Long rallyId) throws ServiceException {
    RallyDTO rally = get(rallyId);
    if (rally == null) throw new ServiceException("Rally " + rallyId + " was not found.");
    List<RouteDTO> routes = routeService.findByRallyId(rallyId);
    if (routes.stream().anyMatch(route -> route.getStatus() == RouteStatus.ACTIVE
        || route.getStatus() == RouteStatus.COMPLETED)) {
      throw new ServiceException("A rally with active or completed routes cannot be deleted.");
    }
    for (RouteDTO route : routes) {
      routeService.delete(route.getId());
    }
    rallyConfigurationPersistence.deleteForRallyAndOrganization(rallyId, rally.getOrganizationId());
    if (rallyPersistence.deleteForOrganization(rallyId, rally.getOrganizationId()) != 1) {
      throw new ServiceException("Rally " + rallyId + " was not found.");
    }
    rallyPersistence.flush();
  }
}
