package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationException;
import com.rallyapp.rallymaster.competition.CompetitionAuthenticationResponse;
import com.rallyapp.rallymaster.competition.CompetitionAuthenticationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Deliberately separate from /api/external: competitors do not authenticate to
 * Keycloak or select an organization before registering for a rally.
 */
@RestController
@RequestMapping("/api/compete")
public class CompetitionAuthenticationRest {
  private final CompetitionAuthenticationService competitionAuthenticationService;

  public CompetitionAuthenticationRest(CompetitionAuthenticationService competitionAuthenticationService) {
    this.competitionAuthenticationService = competitionAuthenticationService;
  }

  @PostMapping("/authenticate")
  public ResponseEntity<CompetitionAuthenticationResponse> authenticate(
      @RequestBody CompetitionAuthenticationRequest request) {
    try {
      return ResponseEntity.ok(
          competitionAuthenticationService.authenticate(request.rallyId(), request.password()));
    } catch (CompetitionAuthenticationException ex) {
      // Do not disclose whether a rally exists, has an active route, or has a password.
      return ResponseEntity.status(401).build();
    }
  }
}
