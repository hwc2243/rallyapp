package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RouteInstructionPersistence;
import com.rallyapp.rallymaster.persistence.RouteItemPersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPlanPersistence;
import com.rallyapp.rallymaster.persistence.RouteTimingPointPersistence;
import com.rallyapp.rallymaster.service.base.BaseRouteServiceImpl;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RouteServiceImpl
  extends BaseRouteServiceImpl<RouteDTO, RouteEntity,Long>
  implements RouteService
{
  
  @Autowired
  protected RouteMapper routeMapper;

  @Autowired
  protected RallyPersistence rallyPersistence;

  @Autowired
  protected RouteInstructionService routeInstructionService;

  @Autowired
  protected CheckpointService checkpointService;

  @Autowired
  protected RouteInstructionPersistence routeInstructionPersistence;

  @Autowired
  protected CheckpointPersistence checkpointPersistence;

  @Autowired
  protected RouteItemPersistence routeItemPersistence;

  @Autowired
  protected RouteTimingPlanPersistence routeTimingPlanPersistence;

  @Autowired
  protected RouteTimingPointPersistence routeTimingPointPersistence;
  
  protected RouteEntity toEntity (RouteDTO dto) {
    RouteEntity entity = routeMapper.toEntity(dto);
    entity.setRally(dto.getRallyId() == null
        ? null
        : rallyPersistence.getReferenceById(dto.getRallyId()));
    return entity;
  }
  
  protected List<RouteEntity> toEntities (List<RouteDTO> dtos) {
    return routeMapper.toEntities(dtos);
  }

  protected RouteDTO toDto (RouteEntity entity) {
    return routeMapper.toDto(entity);
  }
  
  protected List<RouteDTO> toDtos (List<RouteEntity> entities) {
    return routeMapper.toDtos(entities);
  }

  protected Collection<RouteItemDTO> toItemsDtos (RouteEntity entity) {
    return routeMapper.itemsToDtos(entity.getItems());
  }

  /**
   * Updates the route header without merging a detached aggregate.
   *
   * <p>A route owns its route items and timing plan.  Saving a newly mapped
   * RouteEntity for a header-only edit asks Hibernate to merge those cascaded
   * associations as well.  That can orphan route items while their timing
   * points still reference them.  Apply the editable header fields to the
   * managed route instead, leaving the plan and its item graph untouched.</p>
   */
  @Override
  @Transactional
  public RouteDTO update(RouteDTO dto) throws ServiceException {
    if (dto == null || dto.getId() == null || !hasAccess(dto)) {
      throw new ServiceException("Access denied for updating route");
    }

    RouteEntity route = routePersistence.findById(dto.getId())
        .orElseThrow(() -> new ServiceException("Route " + dto.getId() + " was not found."));
    if (!hasAccess(route)) {
      throw new ServiceException("Access denied for updating route with id = " + dto.getId());
    }

    boolean timingPlanInvalidated = !Objects.equals(
        route.getCarZeroStartEpochMillis(), dto.getCarZeroStartEpochMillis())
        || !Objects.equals(route.getTimeZone(), dto.getTimeZone());
    RouteTimingPlanEntity timingPlan = timingPlanInvalidated
        ? routeTimingPlanPersistence.findFirstByOrganizationIdAndRouteId(
            route.getOrganizationId(), route.getId())
        : null;

    route.setName(dto.getName());
    route.setDescription(dto.getDescription());
    route.setStatus(dto.getStatus());
    route.setDefaultSpeed(dto.getDefaultSpeed());
    route.setRestartIntervalMillis(dto.getRestartIntervalMillis());
    route.setDefaultPauseDurationMillis(dto.getDefaultPauseDurationMillis());
    route.setTimeZone(dto.getTimeZone());
    route.setCarZeroStartEpochMillis(dto.getCarZeroStartEpochMillis());
    route.setMaximumCheckpointScore(dto.getMaximumCheckpointScore());
    route.setRally(dto.getRallyId() == null
        ? null
        : rallyPersistence.getReferenceById(dto.getRallyId()));

    if (timingPlan != null) {
      // Break the in-memory association before the bulk delete.  The generated
      // one-to-one mapping cascades in both directions, so entity deletion
      // would otherwise risk deleting the route itself.
      route.setTimingPlan(null);
    }

    RouteDTO saved = toDto(routePersistence.saveAndFlush(route));
    if (timingPlan != null) {
      routeTimingPointPersistence.deleteForTimingPlan(timingPlan.getId());
      routeTimingPlanPersistence.deleteForId(timingPlan.getId());
    }
    publishCrudEvent(com.rallyapp.rallymaster.service.event.CrudOperation.UPDATED, saved);
    return saved;
  }

  /**
   * A route may only be removed while it is still being planned. Hibernate's
   * route associations own the cascade to route items and timing-plan data, so
   * the delete is one transaction and cannot leave a partial plan behind.
   */
  @Override
  @Transactional
  public void delete(Long routeId) throws ServiceException {
    RouteDTO route = get(routeId);
    if (route == null) {
      throw new ServiceException("Route " + routeId + " was not found.");
    }
    if (route.getStatus() != RouteStatus.PLAN) {
      throw new ServiceException("Only planning routes can be deleted.");
    }
    // Remove concrete route items explicitly before the route bulk delete.
    // This works for the polymorphic route-item hierarchy and protects the
    // database FK regardless of whether the collection was initialized.
    for (var instruction : routeInstructionPersistence.findAllForRoute(routeId)) {
      routeInstructionService.delete(instruction.getId());
    }
    for (var checkpoint : checkpointPersistence.findAllForRoute(routeId)) {
      checkpointService.delete(checkpoint.getId());
    }
    // The abstract RouteItem root uses JOINED inheritance. A bulk route delete
    // does not cascade to its table, and older generated mappings can leave a
    // base row even after a concrete service delete. Clear concrete rows first
    // and then the root rows so PostgreSQL never sees route_item.route_id
    // references while removing the route.
    routeItemPersistence.deleteInstructionsForRoute(routeId);
    routeItemPersistence.deleteCheckpointsForRoute(routeId);
    routeItemPersistence.deleteForRoute(routeId);
    if (routePersistence.deleteForOrganization(routeId, route.getOrganizationId()) != 1) {
      throw new ServiceException("Route " + routeId + " was not found.");
    }
    // Force Hibernate to execute the cascading delete before this transaction
    // returns. Without the flush, a subsequent route lookup in the same web
    // request can still resolve the just-removed managed entity.
    routePersistence.flush();
  }

  /** Persists the editable plan as one transaction for reliable mobile saves. */
  @Override
  @Transactional
  public RoutePlanDTO savePlan(Long routeId, RoutePlanDTO plan) throws ServiceException {
    RouteDTO route = get(routeId);
    if (route == null) {
      throw new ServiceException("Route " + routeId + " was not found.");
    }
    // A published route becomes the immutable record used by competitors and
    // their diagnostic telemetry.  Replacing omitted items in an active plan
    // could otherwise delete a checkpoint referenced by that evidence.
    if (route.getStatus() != RouteStatus.PLAN) {
      throw new ServiceException("Only planning routes can be changed.");
    }
    RouteEntity managedRoute = routePersistence.findById(routeId)
        .orElseThrow(() -> new ServiceException("Route " + routeId + " was not found."));

    RoutePlanDTO savedPlan = new RoutePlanDTO();
    Set<Long> instructionIds = new HashSet<>();
    for (var instruction : plan.getRouteInstructions()) {
      if (instruction.getId() != null) {
        var existing = routeInstructionService.get(instruction.getId());
        if (existing == null || (existing.getRouteId() != null
            && !routeId.equals(existing.getRouteId()))) {
          throw new ServiceException("Route instruction does not belong to route " + routeId + ".");
        }
        instructionIds.add(instruction.getId());
      }
      instruction.setRouteId(routeId);
      instruction.setOrganizationId(route.getOrganizationId());
      var savedInstruction =
          instruction.getId() == null ? routeInstructionService.create(instruction)
              : routeInstructionService.update(instruction);
      savedPlan.getRouteInstructions().add(savedInstruction);
      instructionIds.add(savedInstruction.getId());
    }
    Set<Long> checkpointIds = new HashSet<>();
    for (var checkpoint : plan.getCheckpoints()) {
      if (checkpoint.getId() != null) {
        var existing = checkpointService.get(checkpoint.getId());
        if (existing == null || (existing.getRouteId() != null
            && !routeId.equals(existing.getRouteId()))) {
          throw new ServiceException("Checkpoint does not belong to route " + routeId + ".");
        }
        checkpointIds.add(checkpoint.getId());
      }
      checkpoint.setRouteId(routeId);
      checkpoint.setOrganizationId(route.getOrganizationId());
      var savedCheckpoint =
          checkpoint.getId() == null ? checkpointService.create(checkpoint)
              : checkpointService.update(checkpoint);
      savedPlan.getCheckpoints().add(savedCheckpoint);
      checkpointIds.add(savedCheckpoint.getId());
    }
    // Explicit JPQL is used here rather than the generated derived finder.
    // The latter is ambiguous for the inherited route relationship and could
    // return no records, leaving items that the app omitted from its plan.
    for (var existing : routeInstructionPersistence.findAllForRoute(routeId)) {
      if (!instructionIds.contains(existing.getId())) {
        detachFromRoute(managedRoute, existing);
        routeInstructionService.delete(existing.getId());
      }
    }
    for (var existing : checkpointPersistence.findAllForRoute(routeId)) {
      if (!checkpointIds.contains(existing.getId())) {
        detachFromRoute(managedRoute, existing);
        checkpointService.delete(existing.getId());
      }
    }
    return savedPlan;
  }

  private static void detachFromRoute(RouteEntity route, RouteItemEntity item) {
    if (route.getItems() != null) {
      route.getItems().removeIf(existing -> item.getId().equals(existing.getId()));
    }
    item.setRoute(null);
  }
}
