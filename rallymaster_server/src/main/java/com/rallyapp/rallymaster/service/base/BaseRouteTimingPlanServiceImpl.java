package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.base.BaseRouteTimingPlanEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import com.rallyapp.rallymaster.persistence.base.BaseRouteTimingPlanPersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPlanPersistence;
import com.rallyapp.rallymaster.service.base.MultitenantServiceImpl;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseRouteTimingPlanServiceImpl<D extends RouteTimingPlanDTO & Multitenant, E extends RouteTimingPlanEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRouteTimingPlanService<D, ID> {

  @Autowired
  private BaseRouteTimingPlanPersistence<E, ID> baseRouteTimingPlanPersistence;

  @Autowired
  protected RouteTimingPlanPersistence routeTimingPlanPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating routeTimingPlan");
    }
    
    E entity = toEntity(dto);
    E saved = baseRouteTimingPlanPersistence.save(entity);
    D savedDto = toDto(saved);
    publishCrudEvent(CrudOperation.CREATED, savedDto);
    return savedDto;
  }
  
  @Override
  @Transactional
  public void delete (ID id) throws ServiceException
  {
    D deletedDto = serviceEventBus == null ? null : get(id);
    try {
      get(id);
    } catch (ServiceException ex) {
      throw new ServiceException("Access denied for deleting routeTimingPlan with id = " + id);
    }
    
    baseRouteTimingPlanPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRouteTimingPlanPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public D fetchByOrganizationIdAndRouteId (Long routeId)
  {
	return toDto(baseRouteTimingPlanPersistence.findFirstByOrganizationIdAndRouteId(tenantDiscriminator.getOrganizationId(),routeId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRouteTimingPlanPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for routeTimingPlan with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  @Override
  public Collection<RouteTimingPointDTO> getPoints (ID id) throws ServiceException
  {
    Optional<E> optional = baseRouteTimingPlanPersistence.findById(id);
    if (optional.isPresent() && !hasAccess(optional.get())) {
      throw new ServiceException("Access denied for routeTimingPlan with id = " + id);
    }
    return optional.isEmpty() ? null : toPointsDtos(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating routeTimingPlan with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRouteTimingPlanPersistence.save(entity);
    D savedDto = toDto(saved);
    publishCrudEvent(CrudOperation.UPDATED, savedDto);
    return savedDto;
  }

  protected void publishEvent (ServiceEvent event)
  {
    if (serviceEventBus != null) {
      serviceEventBus.publish(event);
    }
  }

  protected void publishCrudEvent (CrudOperation operation, D dto)
  {
    if (dto != null) {
      publishEvent(new EntityCrudEvent<D>(operation, "routeTimingPlan", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
  protected abstract Collection<RouteTimingPointDTO> toPointsDtos (E entity);
}
