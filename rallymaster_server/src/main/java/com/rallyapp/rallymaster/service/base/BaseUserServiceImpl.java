package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseUserDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.entity.base.BaseUserEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.persistence.base.BaseUserPersistence;
import com.rallyapp.rallymaster.persistence.UserPersistence;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseUserServiceImpl<D extends UserDTO, E extends UserEntity, ID>
  implements BaseUserService<D, ID> {

  @Autowired
  private BaseUserPersistence<E, ID> baseUserPersistence;

  @Autowired
  protected UserPersistence userPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseUserPersistence.save(entity);
    D savedDto = toDto(saved);
    publishCrudEvent(CrudOperation.CREATED, savedDto);
    return savedDto;
  }
  
  @Override
  @Transactional
  public void delete (ID id) throws ServiceException
  {
    D deletedDto = serviceEventBus == null ? null : get(id);
    baseUserPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseUserPersistence.findAll();
    return toDtos(entities);
  }

  @Override
  public D fetchByEmailAddress (String emailAddress)
  {
	return toDto(baseUserPersistence.findFirstByEmailAddress(emailAddress));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseUserPersistence.findById(id);

    return optional.isEmpty() ? null : toDto(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseUserPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "user", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
