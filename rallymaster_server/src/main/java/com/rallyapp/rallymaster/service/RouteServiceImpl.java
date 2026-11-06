package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
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
    for (var existing : routeInstructionService.findByRouteId(routeId)) {
      if (!instructionIds.contains(existing.getId())) {
        routeInstructionService.delete(existing.getId());
      }
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
    for (var existing : checkpointService.findByRouteId(routeId)) {
      if (!checkpointIds.contains(existing.getId())) {
        checkpointService.delete(existing.getId());
      }
    }
    return savedPlan;
  }
}
