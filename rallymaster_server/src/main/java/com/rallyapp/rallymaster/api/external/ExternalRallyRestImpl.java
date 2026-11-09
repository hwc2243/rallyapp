package com.rallyapp.rallymaster.api.external;

import com.rallyapp.rallymaster.competition.CompetitionAuthenticationService;
import com.rallyapp.rallymaster.service.ServiceException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRestImpl;

@RestController
@RequestMapping("/api/external/rally")
public class ExternalRallyRestImpl
   extends BaseExternalRallyRestImpl
   implements ExternalRallyRest
{
  private final CompetitionAuthenticationService competitionAuthenticationService;

  public ExternalRallyRestImpl(
      CompetitionAuthenticationService competitionAuthenticationService) {
    this.competitionAuthenticationService = competitionAuthenticationService;
  }

  @GetMapping("/{rallyId}/publish-status")
  public ResponseEntity<RallyPublishStatusResponse> getPublishStatus(
      @PathVariable Long rallyId) {
    try {
      if (rallyService.get(rallyId) == null) {
        return ResponseEntity.notFound().build();
      }
      return ResponseEntity.ok(new RallyPublishStatusResponse(
          competitionAuthenticationService.hasEventPassword(rallyId)));
    } catch (ServiceException ex) {
      return ResponseEntity.status(403).build();
    }
  }
}
