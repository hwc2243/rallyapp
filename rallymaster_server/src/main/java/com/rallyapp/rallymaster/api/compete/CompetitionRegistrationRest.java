package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationException;
import com.rallyapp.rallymaster.competition.CompetitionRegistrationException;
import com.rallyapp.rallymaster.competition.CompetitionRegistrationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/compete/registrations")
public class CompetitionRegistrationRest {
  private static final String DEVICE_ID_HEADER = "X-Competition-Device-Id";
  private final com.rallyapp.rallymaster.competition.CompetitionRegistrationLookupService
      competitionRegistrationLookupService;
  private final CompetitionRegistrationService competitionRegistrationService;

  public CompetitionRegistrationRest(
      CompetitionRegistrationService competitionRegistrationService,
      com.rallyapp.rallymaster.competition.CompetitionRegistrationLookupService
          competitionRegistrationLookupService) {
    this.competitionRegistrationService = competitionRegistrationService;
    this.competitionRegistrationLookupService = competitionRegistrationLookupService;
  }

  @GetMapping("/routes/{routeId}")
  public ResponseEntity<CompetitionRegistrationResponse> findExisting(
      @PathVariable Long routeId,
      @RequestHeader(name = DEVICE_ID_HEADER, required = false) String deviceId) {
    CompetitionRegistrationResponse registration =
        competitionRegistrationLookupService.find(routeId, deviceId);
    return registration == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(registration);
  }

  @PostMapping
  public ResponseEntity<CompetitionRegistrationResponse> register(
      @RequestBody CompetitionRegistrationRequest request) {
    try {
      return ResponseEntity.status(HttpStatus.CREATED)
          .body(competitionRegistrationService.register(request));
    } catch (CompetitionAuthenticationException ex) {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    } catch (CompetitionRegistrationException ex) {
      return ResponseEntity.status(HttpStatus.CONFLICT).build();
    }
  }
}
