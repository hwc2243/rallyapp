package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPointDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.entity.base.BaseRouteTimingPointEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseRouteTimingPointPersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPointPersistence;
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

public abstract class BaseRouteTimingPointServiceImpl<D extends RouteTimingPointDTO & Multitenant, E extends RouteTimingPointEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRouteTimingPointService<D, ID> {

  @Autowired
  private BaseRouteTimingPointPersistence<E, ID> baseRouteTimingPointPersistence;

  @Autowired
  protected RouteTimingPointPersistence routeTimingPointPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating routeTimingPoint");
    }
    
    E entity = toEntity(dto);
    E saved = baseRouteTimingPointPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting routeTimingPoint with id = " + id);
    }
    
    baseRouteTimingPointPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRouteTimingPointPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public D fetchByOrganizationIdAndRouteTimingPlanIdAndRouteItemId (Long routeTimingPlanId, Long routeItemId)
  {
	return toDto(baseRouteTimingPointPersistence.findFirstByOrganizationIdAndRouteTimingPlanIdAndRouteItemId(tenantDiscriminator.getOrganizationId(),routeTimingPlanId, routeItemId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRouteTimingPointPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for routeTimingPoint with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating routeTimingPoint with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRouteTimingPointPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "routeTimingPoint", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
