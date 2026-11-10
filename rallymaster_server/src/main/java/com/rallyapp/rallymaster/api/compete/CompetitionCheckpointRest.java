package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationException;
import com.rallyapp.rallymaster.competition.CompetitionCheckpointDownloadService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/compete/routes")
public class CompetitionCheckpointRest {
  private static final String DEVICE_ID_HEADER = "X-Competition-Device-Id";
  private final CompetitionCheckpointDownloadService competitionCheckpointDownloadService;

  public CompetitionCheckpointRest(
      CompetitionCheckpointDownloadService competitionCheckpointDownloadService) {
    this.competitionCheckpointDownloadService = competitionCheckpointDownloadService;
  }

  @GetMapping("/{routeId}/checkpoints")
  public ResponseEntity<List<CompetitionCheckpointResponse>> download(
      @PathVariable Long routeId,
      @RequestHeader(name = DEVICE_ID_HEADER, required = false) String deviceId) {
    try {
      return ResponseEntity.ok(competitionCheckpointDownloadService.download(routeId, deviceId));
    } catch (CompetitionAuthenticationException ex) {
      return ResponseEntity.status(401).build();
    }
  }
}
