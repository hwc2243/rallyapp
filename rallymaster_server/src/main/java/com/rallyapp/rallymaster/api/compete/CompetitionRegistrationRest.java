package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationException;
import com.rallyapp.rallymaster.competition.CompetitionRegistrationException;
import com.rallyapp.rallymaster.competition.CompetitionRegistrationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/compete/registrations")
public class CompetitionRegistrationRest {
  private final CompetitionRegistrationService competitionRegistrationService;

  public CompetitionRegistrationRest(CompetitionRegistrationService competitionRegistrationService) {
    this.competitionRegistrationService = competitionRegistrationService;
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
