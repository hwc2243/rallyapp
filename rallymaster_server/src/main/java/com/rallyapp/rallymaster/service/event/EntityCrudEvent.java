package com.rallyapp.rallymaster.service.event;

import java.time.Instant;

public final class EntityCrudEvent<T> implements ServiceEvent {

  private final CrudOperation operation;
  private final String entityName;
  private final Object entityId;
  private final T entity;
  private final Instant occurredAt;

  public EntityCrudEvent(CrudOperation operation, String entityName, Object entityId, T entity) {
    this.operation = operation;
    this.entityName = entityName;
    this.entityId = entityId;
    this.entity = entity;
    this.occurredAt = Instant.now();
  }

  public CrudOperation getOperation() {
    return operation;
  }

  public String getEntityName() {
    return entityName;
  }

  public Object getEntityId() {
    return entityId;
  }

  public T getEntity() {
    return entity;
  }

  public Instant getOccurredAt() {
    return occurredAt;
  }
}
