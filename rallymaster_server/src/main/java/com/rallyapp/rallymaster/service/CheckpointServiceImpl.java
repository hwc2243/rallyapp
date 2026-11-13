package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.RouteInstructionPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.service.base.BaseCheckpointServiceImpl;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CheckpointServiceImpl
  extends BaseCheckpointServiceImpl<CheckpointDTO, CheckpointEntity,Long>
  implements CheckpointService
{
  
  @Autowired
  protected CheckpointMapper checkpointMapper;

  @Autowired
  protected RoutePersistence routePersistence;

  @Autowired
  protected RouteInstructionPersistence routeInstructionPersistence;

  /**
   * START is the definitive discovery point for a route. It is created before
   * vehicle calibration, must be unique, and always occupies canonical
   * position/checkpoint number one.
   */
  @Override
  @Transactional
  public CheckpointDTO create(CheckpointDTO dto) throws ServiceException {
    if (dto.getCheckpointType() == CheckpointCheckpointType.START) {
      validateNewStart(dto);
      shiftPlanningItemsForStart(dto.getRouteId());
      dto.setPosition(1L);
      dto.setCheckpointNumber(1L);
    }
    return super.create(dto);
  }

  @Override
  @Transactional
  public CheckpointDTO update(CheckpointDTO dto) throws ServiceException {
    CheckpointDTO existing = dto.getId() == null ? null : get(dto.getId());
    if (existing != null &&
        existing.getCheckpointType() == CheckpointCheckpointType.START &&
        dto.getCheckpointType() != CheckpointCheckpointType.START) {
      throw new ServiceException("A START checkpoint cannot be changed to another type.");
    }
    if (dto.getCheckpointType() == CheckpointCheckpointType.START) {
      validateStart(dto);
    }
    return super.update(dto);
  }

  private void validateNewStart(CheckpointDTO start) throws ServiceException {
    if (start.getRouteId() == null) {
      throw new ServiceException("A START checkpoint must belong to a route.");
    }
    RouteStatus status = routePersistence.findById(start.getRouteId())
        .orElseThrow(() -> new ServiceException("Route " + start.getRouteId() + " was not found."))
        .getStatus();
    if (status != RouteStatus.PLAN) {
      throw new ServiceException("Only planning routes can be changed.");
    }
    if (!checkpointPersistence.findAllForRouteAndCheckpointType(
        start.getRouteId(), CheckpointCheckpointType.START).isEmpty()) {
      throw new ServiceException("A route may have only one START checkpoint.");
    }
  }

  private void validateStart(CheckpointDTO checkpoint) throws ServiceException {
    if (checkpoint.getRouteId() == null) {
      throw new ServiceException("A START checkpoint must belong to a route.");
    }
    boolean duplicate = checkpointPersistence
        .findAllForRouteAndCheckpointType(checkpoint.getRouteId(), CheckpointCheckpointType.START)
        .stream()
        .anyMatch(existing -> !Objects.equals(existing.getId(), checkpoint.getId()));
    if (duplicate) {
      throw new ServiceException("A route may have only one START checkpoint.");
    }
  }

  private void shiftPlanningItemsForStart(Long routeId) {
    routeInstructionPersistence.findAllForRoute(routeId).forEach(instruction -> {
      if (instruction.getPosition() != null) {
        instruction.setPosition(instruction.getPosition() + 1);
      }
      routeInstructionPersistence.save(instruction);
    });
    checkpointPersistence.findAllForRoute(routeId).forEach(checkpoint -> {
      if (checkpoint.getPosition() != null) {
        checkpoint.setPosition(checkpoint.getPosition() + 1);
      }
      if (checkpoint.getCheckpointNumber() != null) {
        checkpoint.setCheckpointNumber(checkpoint.getCheckpointNumber() + 1);
      }
      checkpointPersistence.save(checkpoint);
    });
  }

  
  protected CheckpointEntity toEntity (CheckpointDTO dto) {
    CheckpointEntity entity = checkpointMapper.toEntity(dto);
    entity.setRoute(dto.getRouteId() == null
        ? null
        : routePersistence.getReferenceById(dto.getRouteId()));
    return entity;
  }
  
  protected List<CheckpointEntity> toEntities (List<CheckpointDTO> dtos) {
    return checkpointMapper.toEntities(dtos);
  }

  protected CheckpointDTO toDto (CheckpointEntity entity) {
    return checkpointMapper.toDto(entity);
  }
  
  protected List<CheckpointDTO> toDtos (List<CheckpointEntity> entities) {
    return checkpointMapper.toDtos(entities);
  }

}
