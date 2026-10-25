package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseOrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.entity.base.BaseOrganizationMembershipEntity;
import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import com.rallyapp.rallymaster.persistence.base.BaseOrganizationMembershipPersistence;
import com.rallyapp.rallymaster.persistence.OrganizationMembershipPersistence;
import com.rallyapp.rallymaster.service.base.MultitenantServiceImpl;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseOrganizationMembershipServiceImpl<D extends OrganizationMembershipDTO & Multitenant, E extends OrganizationMembershipEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseOrganizationMembershipService<D, ID> {

  @Autowired
  private BaseOrganizationMembershipPersistence<E, ID> baseOrganizationMembershipPersistence;

  @Autowired
  protected OrganizationMembershipPersistence organizationMembershipPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating organizationMembership");
    }
    
    E entity = toEntity(dto);
    E saved = baseOrganizationMembershipPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting organizationMembership with id = " + id);
    }
    
    baseOrganizationMembershipPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseOrganizationMembershipPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public List<D> findByUserId (Long userId)
  {
	return toDtos(baseOrganizationMembershipPersistence.findByUserId(userId));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseOrganizationMembershipPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for organizationMembership with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating organizationMembership with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseOrganizationMembershipPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "organizationMembership", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
