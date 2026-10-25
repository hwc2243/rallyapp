package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRallyDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.entity.base.BaseRallyEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseRallyPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.service.base.MultitenantServiceImpl;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseRallyServiceImpl<D extends RallyDTO & Multitenant, E extends RallyEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseRallyService<D, ID> {

  @Autowired
  private BaseRallyPersistence<E, ID> baseRallyPersistence;

  @Autowired
  protected RallyPersistence rallyPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating rally");
    }
    
    E entity = toEntity(dto);
    E saved = baseRallyPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting rally with id = " + id);
    }
    
    baseRallyPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRallyPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRallyPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for rally with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating rally with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseRallyPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "rally", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
