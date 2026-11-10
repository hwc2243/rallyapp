package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.api.compete.CompetitionCheckpointResponse;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyEntryPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Supplies the selected route's checkpoint plan to its registered primary device. */
@Service
public class CompetitionCheckpointDownloadService {
  private final CheckpointPersistence checkpointPersistence;
  private final RallyEntryPersistence rallyEntryPersistence;
  private final RoutePersistence routePersistence;

  public CompetitionCheckpointDownloadService(
      CheckpointPersistence checkpointPersistence,
      RallyEntryPersistence rallyEntryPersistence,
      RoutePersistence routePersistence) {
    this.checkpointPersistence = checkpointPersistence;
    this.rallyEntryPersistence = rallyEntryPersistence;
    this.routePersistence = routePersistence;
  }

  @Transactional(readOnly = true)
  public List<CompetitionCheckpointResponse> download(Long routeId, String deviceId) {
    if (routeId == null || deviceId == null || deviceId.isBlank()) {
      throw new CompetitionAuthenticationException();
    }
    RouteEntity route = routePersistence.findById(routeId)
        .orElseThrow(CompetitionAuthenticationException::new);
    if (route.getStatus() != RouteStatus.ACTIVE
        || rallyEntryPersistence.findFirstByRouteAndPrimaryDeviceId(routeId, deviceId) == null) {
      throw new CompetitionAuthenticationException();
    }
    return checkpointPersistence.findAllForRoute(routeId).stream()
        .sorted(Comparator.comparing(CheckpointEntity::getPosition,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .map(this::toResponse)
        .toList();
  }

  private CompetitionCheckpointResponse toResponse(CheckpointEntity checkpoint) {
    return new CompetitionCheckpointResponse(
        checkpoint.getId(),
        checkpoint.getCheckpointNumber(),
        checkpoint.getCheckpointType() == null ? null : checkpoint.getCheckpointType().getName(),
        checkpoint.getName(),
        checkpoint.getLatitude(),
        checkpoint.getLongitude(),
        checkpoint.getHeading(),
        checkpoint.getDistance(),
        checkpoint.getNotes());
  }
}
