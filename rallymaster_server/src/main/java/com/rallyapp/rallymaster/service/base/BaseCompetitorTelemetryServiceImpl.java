package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.entity.base.BaseCompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.persistence.base.BaseCompetitorTelemetryPersistence;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryPersistence;
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

public abstract class BaseCompetitorTelemetryServiceImpl<D extends CompetitorTelemetryDTO & Multitenant, E extends CompetitorTelemetryEntity & Multitenant, ID>
  extends MultitenantServiceImpl
  implements BaseCompetitorTelemetryService<D, ID> {

  @Autowired
  private BaseCompetitorTelemetryPersistence<E, ID> baseCompetitorTelemetryPersistence;

  @Autowired
  protected CompetitorTelemetryPersistence competitorTelemetryPersistence;

  @Autowired(required = false)
  protected ServiceEventBus serviceEventBus;


    @Override
  @Transactional
  public D create (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for creating competitorTelemetry");
    }
    
    E entity = toEntity(dto);
    E saved = baseCompetitorTelemetryPersistence.save(entity);
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
      throw new ServiceException("Access denied for deleting competitorTelemetry with id = " + id);
    }
    
    baseCompetitorTelemetryPersistence.deleteById(id);
    if (deletedDto != null) {
      publishCrudEvent(CrudOperation.DELETED, deletedDto);
    }
  }
  
  @Override
  public List<D> findAll () throws ServiceException
  {
    List<E> entities = baseCompetitorTelemetryPersistence.findByOrganizationId(tenantDiscriminator.getOrganizationId());
    return toDtos(entities);
  }

  @Override
  public D fetchByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt (Long rallyEntryId, Long checkpointId, java.time.LocalDateTime occurredAt)
  {
	return toDto(baseCompetitorTelemetryPersistence.findFirstByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt(tenantDiscriminator.getOrganizationId(),rallyEntryId, checkpointId, occurredAt));
  }


  @Override
  public D get (ID id) throws ServiceException
  {
    Optional<E> optional = baseCompetitorTelemetryPersistence.findById(id);

    if (optional.isPresent()) {
      if (!hasAccess(optional.get())) {
		throw new ServiceException("Access denied for competitorTelemetry with id = " + id);
	  }
	}
    return optional.isEmpty() ? null : toDto(optional.get());
  }

  @Override
  public List<D> findByRouteId (Long routeId)
  {
    return toDtos(baseCompetitorTelemetryPersistence.findByOrganizationIdAndRoute_Id(tenantDiscriminator.getOrganizationId(), routeId));
  }
  @Override
  public Collection<CompetitorTelemetryDataDTO> getData (ID id) throws ServiceException
  {
    Optional<E> optional = baseCompetitorTelemetryPersistence.findById(id);
    if (optional.isPresent() && !hasAccess(optional.get())) {
      throw new ServiceException("Access denied for competitorTelemetry with id = " + id);
    }
    return optional.isEmpty() ? null : toDataDtos(optional.get());
  }
  
  @Override
  @Transactional
  public D update (D dto) throws ServiceException
  {
    if (!hasAccess(dto)) {
      throw new ServiceException("Access denied for updating competitorTelemetry with id = " + dto.getId());
    }
    E entity = toEntity(dto);
    E saved = baseCompetitorTelemetryPersistence.save(entity);
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
      publishEvent(new EntityCrudEvent<D>(operation, "competitorTelemetry", dto.getId(), dto));
    }
  }

  protected abstract E toEntity (D dto);
  protected abstract List<E> toEntities (List<D> dtos);

  protected abstract D toDto (E entity);
  protected abstract List<D> toDtos (List<E> entities);
  protected abstract Collection<CompetitorTelemetryDataDTO> toDataDtos (E entity);
}
