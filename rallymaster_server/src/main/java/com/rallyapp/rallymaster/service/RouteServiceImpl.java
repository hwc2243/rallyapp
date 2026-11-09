package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RouteInstructionPersistence;
import com.rallyapp.rallymaster.service.base.BaseRouteServiceImpl;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
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

  /** Persists the editable plan as one transaction for reliable mobile saves. */
  @Override
  @Transactional
  public RoutePlanDTO savePlan(Long routeId, RoutePlanDTO plan) throws ServiceException {
    RouteDTO route = get(routeId);
    if (route == null) {
      throw new ServiceException("Route " + routeId + " was not found.");
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
