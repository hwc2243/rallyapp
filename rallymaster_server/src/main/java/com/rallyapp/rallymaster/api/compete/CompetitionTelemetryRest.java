package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationException;
import com.rallyapp.rallymaster.competition.CompetitionTelemetryException;
import com.rallyapp.rallymaster.competition.CompetitionTelemetryUploadService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Device-authenticated upload of raw checkpoint detection evidence. */
@RestController
@RequestMapping("/api/compete/routes")
public class CompetitionTelemetryRest {
  private static final String DEVICE_ID_HEADER = "X-Competition-Device-Id";
  private final CompetitionTelemetryUploadService telemetryUploadService;

  public CompetitionTelemetryRest(CompetitionTelemetryUploadService telemetryUploadService) {
    this.telemetryUploadService = telemetryUploadService;
  }

  @PostMapping("/{routeId}/telemetry")
  public ResponseEntity<CompetitionTelemetryUploadResponse> upload(
      @PathVariable Long routeId,
      @RequestHeader(name = DEVICE_ID_HEADER, required = false) String deviceId,
      @RequestBody CompetitionTelemetryUploadRequest request) {
    try {
      return ResponseEntity.status(HttpStatus.CREATED)
          .body(telemetryUploadService.upload(routeId, deviceId, request));
    } catch (CompetitionAuthenticationException ex) {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    } catch (CompetitionTelemetryException ex) {
      return ResponseEntity.badRequest().build();
    }
  }
}
