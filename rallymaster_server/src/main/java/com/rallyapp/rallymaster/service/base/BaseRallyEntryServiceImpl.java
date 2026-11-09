package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRallyEntryDTO;
import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.entity.base.BaseRallyEntryEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseRallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
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

public abstract class BaseRallyEntryServiceImpl<D extends RallyEntryDTO & Multitenant, E extends RallyEntryEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRallyEntryService<D, ID> {

  @Autowired
  private BaseRallyEntryPersistence<E, ID> baseRallyEntryPersistence;

  @Autowired
  protected RallyEntryPersistence rallyEntryPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating rallyEntry");
    }
    
    E entity = toEntity(dto);
    E saved = baseRallyEntryPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting rallyEntry with id = " + id);
    }
    
    baseRallyEntryPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRallyEntryPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public D fetchByOrganizationIdAndRallyIdAndCarNumber (Long rallyId, Long carNumber)
  {
	return toDto(baseRallyEntryPersistence.findFirstByOrganizationIdAndRallyIdAndCarNumber(tenantDiscriminator.getOrganizationId(),rallyId, carNumber));
  }

  @Override
  public D fetchByOrganizationIdAndRallyIdAndPrimaryDeviceId (Long rallyId, String primaryDeviceId)
  {
	return toDto(baseRallyEntryPersistence.findFirstByOrganizationIdAndRallyIdAndPrimaryDeviceId(tenantDiscriminator.getOrganizationId(),rallyId, primaryDeviceId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRallyEntryPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for rallyEntry with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  @Override
  public List<D> findByRouteId (Long routeId)
  {
    return toDtos(baseRallyEntryPersistence.findByOrganizationIdAndRoute_Id(tenantDiscriminator.getOrganizationId(), routeId));
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating rallyEntry with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRallyEntryPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "rallyEntry", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
