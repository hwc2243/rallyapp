package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRouteDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.entity.base.BaseRouteEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseRoutePersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
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

public abstract class BaseRouteServiceImpl<D extends RouteDTO & Multitenant, E extends RouteEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRouteService<D, ID> {

  @Autowired
  private BaseRoutePersistence<E, ID> baseRoutePersistence;

  @Autowired
  protected RoutePersistence routePersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating route");
    }
    
    E entity = toEntity(dto);
    E saved = baseRoutePersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting route with id = " + id);
    }
    
    baseRoutePersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRoutePersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRoutePersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for route with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  @Override
  public List<D> findByRallyId (Long rallyId)
  {
    return toDtos(baseRoutePersistence.findByOrganizationIdAndRally_Id(tenantDiscriminator.getOrganizationId(), rallyId));
  }
  @Override
  public Collection<RouteItemDTO> getItems (ID id) throws ServiceException
  {
    Optional<E> optional = baseRoutePersistence.findById(id);
    if (optional.isPresent() && !hasAccess(optional.get())) {
      throw new ServiceException("Access denied for route with id = " + id);
    }
    return optional.isEmpty() ? null : toItemsDtos(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating route with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRoutePersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "route", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
  protected abstract Collection<RouteItemDTO> toItemsDtos (E entity);
}
