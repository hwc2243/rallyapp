package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRallyConfigurationDTO;
import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.entity.base.BaseRallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import com.rallyapp.rallymaster.persistence.base.BaseRallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
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

public abstract class BaseRallyConfigurationServiceImpl<D extends RallyConfigurationDTO & Multitenant, E extends RallyConfigurationEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRallyConfigurationService<D, ID> {

  @Autowired
  private BaseRallyConfigurationPersistence<E, ID> baseRallyConfigurationPersistence;

  @Autowired
  protected RallyConfigurationPersistence rallyConfigurationPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating rallyConfiguration");
    }
    
    E entity = toEntity(dto);
    E saved = baseRallyConfigurationPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting rallyConfiguration with id = " + id);
    }
    
    baseRallyConfigurationPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRallyConfigurationPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public D fetchByOrganizationIdAndRallyId (Long rallyId)
  {
	return toDto(baseRallyConfigurationPersistence.findFirstByOrganizationIdAndRallyId(tenantDiscriminator.getOrganizationId(),rallyId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRallyConfigurationPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for rallyConfiguration with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating rallyConfiguration with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRallyConfigurationPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "rallyConfiguration", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
