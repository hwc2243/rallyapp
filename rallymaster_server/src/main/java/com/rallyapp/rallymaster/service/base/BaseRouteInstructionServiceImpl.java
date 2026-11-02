package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseRouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.entity.base.BaseRouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRouteInstructionPersistence;
import com.rallyapp.rallymaster.persistence.RouteInstructionPersistence;
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

public abstract class BaseRouteInstructionServiceImpl<D extends RouteInstructionDTO, E extends RouteInstructionEntity, ID>
  implements BaseRouteInstructionService<D, ID> {

  @Autowired
  private BaseRouteInstructionPersistence<E, ID> baseRouteInstructionPersistence;

  @Autowired
  protected RouteInstructionPersistence routeInstructionPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseRouteInstructionPersistence.save(entity);
    D savedDto = toDto(saved);
    publishCrudEvent(CrudOperation.CREATED, savedDto);
    return savedDto;
  }
  
  @Override
  @Transactional
  public void delete (ID id) throws ServiceException
  {
    D deletedDto = serviceEventBus == null ? null : get(id);
    baseRouteInstructionPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseRouteInstructionPersistence.findAll();
    return toDtos(entities);
  }

  @Override
  public List<D> findByRouteId (Long routeId)
  {
	return toDtos(baseRouteInstructionPersistence.findByRouteId(routeId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseRouteInstructionPersistence.findById(id);

    return optional.isEmpty() ? null : toDto(optional.get());
  }

  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseRouteInstructionPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "routeInstruction", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
