package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseOrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.entity.base.BaseOrganizationEntity;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.persistence.base.BaseOrganizationPersistence;
import com.rallyapp.rallymaster.persistence.OrganizationPersistence;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseOrganizationServiceImpl<D extends OrganizationDTO, E extends OrganizationEntity, ID>
  implements BaseOrganizationService<D, ID> {

  @Autowired
  private BaseOrganizationPersistence<E, ID> baseOrganizationPersistence;

  @Autowired
  protected OrganizationPersistence organizationPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseOrganizationPersistence.save(entity);
    D savedDto = toDto(saved);
    publishCrudEvent(CrudOperation.CREATED, savedDto);
    return savedDto;
  }
  
  @Override
  @Transactional
  public void delete (ID id) throws ServiceException
  {
    D deletedDto = serviceEventBus == null ? null : get(id);
    baseOrganizationPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseOrganizationPersistence.findAll();
    return toDtos(entities);
  }

  @Override
  public D fetchByName (String name)
  {
	return toDto(baseOrganizationPersistence.findFirstByName(name));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseOrganizationPersistence.findById(id);

    return optional.isEmpty() ? null : toDto(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    E entity = toEntity(dto);
    E saved = baseOrganizationPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "organization", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
