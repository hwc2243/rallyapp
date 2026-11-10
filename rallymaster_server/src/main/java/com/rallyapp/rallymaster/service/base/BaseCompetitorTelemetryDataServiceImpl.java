package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.entity.base.BaseCompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseCompetitorTelemetryDataPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryDataPersistence;
import com.rallyapp.rallymaster.service.base.MultitenantServiceImpl;
import com.rallyapp.rallymaster.service.event.CrudOperation;
import com.rallyapp.rallymaster.service.event.EntityCrudEvent;
import com.rallyapp.rallymaster.service.event.ServiceEvent;
import com.rallyapp.rallymaster.service.event.ServiceEventBus;
import com.rallyapp.rallymaster.service.ServiceException;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

public abstract class BaseCompetitorTelemetryDataServiceImpl<D extends CompetitorTelemetryDataDTO & Multitenant, E extends CompetitorTelemetryDataEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseCompetitorTelemetryDataService<D, ID> {

  @Autowired
  private BaseCompetitorTelemetryDataPersistence<E, ID> baseCompetitorTelemetryDataPersistence;

  @Autowired
  protected CompetitorTelemetryDataPersistence competitorTelemetryDataPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating competitorTelemetryData");
    }
    
    E entity = toEntity(dto);
    E saved = baseCompetitorTelemetryDataPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting competitorTelemetryData with id = " + id);
    }
    
    baseCompetitorTelemetryDataPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseCompetitorTelemetryDataPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseCompetitorTelemetryDataPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for competitorTelemetryData with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  @Override
  public List<D> findByCompetitorTelemetryId (Long competitorTelemetryId)
  {
    return toDtos(baseCompetitorTelemetryDataPersistence.findByOrganizationIdAndCompetitorTelemetry_Id(tenantDiscriminator.getOrganizationId(), competitorTelemetryId));
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating competitorTelemetryData with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseCompetitorTelemetryDataPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "competitorTelemetryData", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
}
