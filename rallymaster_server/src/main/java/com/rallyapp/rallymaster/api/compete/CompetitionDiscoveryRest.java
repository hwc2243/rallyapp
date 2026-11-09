package com.rallyapp.rallymaster.api.compete;

import com.rallyapp.rallymaster.competition.CompetitionDiscoveryService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/compete/events")
public class CompetitionDiscoveryRest {
  private final CompetitionDiscoveryService competitionDiscoveryService;

  public CompetitionDiscoveryRest(CompetitionDiscoveryService competitionDiscoveryService) {
    this.competitionDiscoveryService = competitionDiscoveryService;
  }

  @GetMapping("/discover")
  public ResponseEntity<List<DiscoveredRallyResponse>> discover(
      @RequestParam double latitude,
      @RequestParam double longitude) {
    try {
      return ResponseEntity.ok(competitionDiscoveryService.discover(latitude, longitude));
    } catch (IllegalArgumentException ex) {
      return ResponseEntity.badRequest().build();
    }
  }

  @GetMapping("/{rallyId}/routes")
  public ResponseEntity<List<DiscoveredRouteResponse>> activeRoutes(
      @PathVariable Long rallyId) {
    try {
      return ResponseEntity.ok(competitionDiscoveryService.activeRoutes(rallyId));
    } catch (IllegalArgumentException ex) {
      return ResponseEntity.badRequest().build();
    }
  }
}
