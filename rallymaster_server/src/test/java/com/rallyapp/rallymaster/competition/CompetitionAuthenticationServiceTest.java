package com.rallyapp.rallymaster.competition;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.RouteTimingPlanCalculationService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

class CompetitionAuthenticationServiceTest {

  private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

  @Test
  void authenticatesAnActiveEventAndReturnsAnOpaqueRegistrationToken() {
    RallyConfigurationPersistence configurationPersistence = mock(RallyConfigurationPersistence.class);
    CheckpointPersistence checkpointPersistence = mock(CheckpointPersistence.class);
    RallyPersistence rallyPersistence = mock(RallyPersistence.class);
    CompetitionAuthenticationTokenRepository tokenRepository = mock(CompetitionAuthenticationTokenRepository.class);
    RoutePersistence routePersistence = mock(RoutePersistence.class);
    RouteService routeService = mock(RouteService.class);
    RouteTimingPlanCalculationService timingPlanCalculationService =
        mock(RouteTimingPlanCalculationService.class);
    CompetitionAuthenticationService service = new CompetitionAuthenticationService(
        configurationPersistence, checkpointPersistence, rallyPersistence, tokenRepository,
        routePersistence, routeService, timingPlanCalculationService, passwordEncoder);
    long rallyId = 42L;
    RallyConfigurationEntity configuration = new RallyConfigurationEntity();
    configuration.setEventPasswordHash(passwordEncoder.encode("event-secret"));
    when(configurationPersistence.findFirstByRally_Id(rallyId)).thenReturn(configuration);
    when(routePersistence.findByRally_IdAndStatus(rallyId, RouteStatus.ACTIVE))
        .thenReturn(List.of(mock(RouteEntity.class)));

    CompetitionAuthenticationResponse response = service.authenticate(rallyId, "event-secret");

    assertNotNull(response.registrationToken());
    assertFalse(response.registrationToken().isBlank());
    assertNotNull(response.expiresAt());
    org.mockito.Mockito.verify(tokenRepository).save(any(CompetitionAuthenticationTokenEntity.class));
  }

  @Test
  void rejectsAnIncorrectPasswordWithoutCreatingAToken() {
    RallyConfigurationPersistence configurationPersistence = mock(RallyConfigurationPersistence.class);
    CheckpointPersistence checkpointPersistence = mock(CheckpointPersistence.class);
    RallyPersistence rallyPersistence = mock(RallyPersistence.class);
    CompetitionAuthenticationTokenRepository tokenRepository = mock(CompetitionAuthenticationTokenRepository.class);
    RoutePersistence routePersistence = mock(RoutePersistence.class);
    RouteService routeService = mock(RouteService.class);
    RouteTimingPlanCalculationService timingPlanCalculationService =
        mock(RouteTimingPlanCalculationService.class);
    CompetitionAuthenticationService service = new CompetitionAuthenticationService(
        configurationPersistence, checkpointPersistence, rallyPersistence, tokenRepository,
        routePersistence, routeService, timingPlanCalculationService, passwordEncoder);
    RallyConfigurationEntity configuration = new RallyConfigurationEntity();
    configuration.setEventPasswordHash(passwordEncoder.encode("event-secret"));
    when(configurationPersistence.findFirstByRally_Id(42L)).thenReturn(configuration);
    when(routePersistence.findByRally_IdAndStatus(eq(42L), eq(RouteStatus.ACTIVE)))
        .thenReturn(List.of(mock(RouteEntity.class)));

    assertThrows(CompetitionAuthenticationException.class,
        () -> service.authenticate(42L, "wrong-password"));
    org.mockito.Mockito.verifyNoInteractions(tokenRepository);
  }
}
