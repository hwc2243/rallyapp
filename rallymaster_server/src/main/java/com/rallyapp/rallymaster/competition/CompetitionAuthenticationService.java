package com.rallyapp.rallymaster.competition;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.persistence.RallyPersistence;
import com.rallyapp.rallymaster.persistence.RoutePersistence;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.RouteTimingPlanCalculationService;
import com.rallyapp.rallymaster.service.ServiceException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Comparator;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Manages short-lived password proof for competitor registration. */
@Service
public class CompetitionAuthenticationService {
  static final Duration REGISTRATION_TOKEN_LIFETIME = Duration.ofMinutes(15);

  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final CheckpointPersistence checkpointPersistence;
  private final RallyPersistence rallyPersistence;
  private final CompetitionAuthenticationTokenRepository tokenRepository;
  private final RoutePersistence routePersistence;
  private final RouteService routeService;
  private final RouteTimingPlanCalculationService routeTimingPlanCalculationService;
  private final PasswordEncoder passwordEncoder;
  private final SecureRandom secureRandom = new SecureRandom();

  public CompetitionAuthenticationService(
      RallyConfigurationPersistence rallyConfigurationPersistence,
      CheckpointPersistence checkpointPersistence,
      RallyPersistence rallyPersistence,
      CompetitionAuthenticationTokenRepository tokenRepository,
      RoutePersistence routePersistence,
      RouteService routeService,
      RouteTimingPlanCalculationService routeTimingPlanCalculationService,
      PasswordEncoder passwordEncoder) {
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.checkpointPersistence = checkpointPersistence;
    this.rallyPersistence = rallyPersistence;
    this.tokenRepository = tokenRepository;
    this.routePersistence = routePersistence;
    this.routeService = routeService;
    this.routeTimingPlanCalculationService = routeTimingPlanCalculationService;
    this.passwordEncoder = passwordEncoder;
  }

  /** Sets the shared event password while an authorized RallyMaster publishes a route. */
  @Transactional
  public RouteDTO publish(Long routeId, String eventPassword) throws ServiceException {
    RouteDTO route = routeService.get(routeId);
    if (route == null || route.getRallyId() == null) {
      throw new ServiceException("Route not found");
    }
    if (route.getStatus() == RouteStatus.COMPLETED) {
      throw new ServiceException("A completed route cannot be published.");
    }
    RouteEntity routeEntity = routePersistence.findById(routeId)
        .orElseThrow(() -> new ServiceException("Route not found"));
    validatePublishableRoute(routeEntity);
    routeTimingPlanCalculationService.calculateForRoute(routeId);

    route.setStatus(RouteStatus.ACTIVE);
    RouteDTO publishedRoute = routeService.update(route);
    RallyConfigurationEntity configuration = rallyConfigurationPersistence
        .findFirstByRally_Id(route.getRallyId());
    if (configuration == null) {
      requirePassword(eventPassword);
      configuration = new RallyConfigurationEntity();
      configuration.setRally(rallyPersistence.getReferenceById(route.getRallyId()));
      configuration.setOrganizationId(route.getOrganizationId());
      applyDefaults(configuration);
    }
    if (configuration.getEventPasswordHash() == null) {
      requirePassword(eventPassword);
      configuration.setEventPasswordHash(passwordEncoder.encode(eventPassword));
    }
    rallyConfigurationPersistence.save(configuration);
    return publishedRoute;
  }

  /** Returns only whether a rally already has a configured event password. */
  @Transactional(readOnly = true)
  public boolean hasEventPassword(Long rallyId) {
    RallyConfigurationEntity configuration = rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
    return configuration != null && configuration.getEventPasswordHash() != null
        && !configuration.getEventPasswordHash().isBlank();
  }

  @Transactional
  public CompetitionAuthenticationResponse authenticate(Long rallyId, String eventPassword) {
    if (rallyId == null || eventPassword == null || eventPassword.isBlank()) {
      throw new CompetitionAuthenticationException();
    }
    RallyConfigurationEntity configuration = rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
    if (configuration == null || configuration.getEventPasswordHash() == null
        || !hasActiveRoute(rallyId)
        || !passwordEncoder.matches(eventPassword, configuration.getEventPasswordHash())) {
      throw new CompetitionAuthenticationException();
    }

    byte[] rawToken = new byte[32];
    secureRandom.nextBytes(rawToken);
    String token = Base64.getUrlEncoder().withoutPadding().encodeToString(rawToken);
    Instant expiresAt = Instant.now().plus(REGISTRATION_TOKEN_LIFETIME);
    tokenRepository.save(new CompetitionAuthenticationTokenEntity(rallyId, digest(token), expiresAt));
    return new CompetitionAuthenticationResponse(token, expiresAt);
  }

  /** Used by the future registration service. Tokens are single-use by design. */
  @Transactional
  public void consumeRegistrationToken(Long rallyId, String token) {
    if (rallyId == null || token == null || token.isBlank()) {
      throw new CompetitionAuthenticationException();
    }
    CompetitionAuthenticationTokenEntity authenticationToken = tokenRepository.findByTokenHash(digest(token))
        .orElseThrow(CompetitionAuthenticationException::new);
    if (!authenticationToken.isUsableFor(rallyId, Instant.now())) {
      throw new CompetitionAuthenticationException();
    }
    authenticationToken.markUsed(Instant.now());
  }

  private boolean hasActiveRoute(Long rallyId) {
    return !routePersistence.findByRally_IdAndStatus(rallyId, RouteStatus.ACTIVE).isEmpty();
  }

  private void validatePublishableRoute(RouteEntity route) throws ServiceException {
    var items = route.getItems().stream()
        .filter(item -> !Boolean.TRUE.equals(item.getDeleted()))
        .sorted(Comparator.comparing(RouteItemEntity::getPosition,
            Comparator.nullsLast(Comparator.naturalOrder())))
        .toList();

    var startCheckpoints = items.stream()
        .filter(CheckpointEntity.class::isInstance)
        .map(CheckpointEntity.class::cast)
        .filter(checkpoint -> checkpoint.getCheckpointType() == CheckpointCheckpointType.START)
        .toList();
    if (startCheckpoints.size() != 1) {
      throw new ServiceException("A route must have exactly one START checkpoint before it can be published.");
    }
    CheckpointEntity start = startCheckpoints.getFirst();
    if (start.getLatitude() == null || start.getLongitude() == null) {
      throw new ServiceException("The START checkpoint must have a latitude and longitude before publishing.");
    }

    boolean freeZoneOpen = false;
    boolean transitOpen = false;
    for (RouteItemEntity item : items) {
      if (item.getDistance() == null) {
        throw new ServiceException("Every route item needs a distance before publishing.");
      }
      if (item instanceof CheckpointEntity checkpoint) {
        if (checkpoint.getLatitude() == null || checkpoint.getLongitude() == null) {
          throw new ServiceException("Every checkpoint needs a latitude and longitude before publishing.");
        }
        if (freeZoneOpen || transitOpen) {
          throw new ServiceException("Checkpoints cannot appear inside a free zone or transit section.");
        }
        continue;
      }
      if (!(item instanceof RouteInstructionEntity instruction)) continue;

      RouteInstructionInstructionType type = instruction.getInstructionType();
      if (type == RouteInstructionInstructionType.BEGIN_FREE_ZONE) {
        if (freeZoneOpen || transitOpen) {
          throw new ServiceException("A free zone cannot begin inside another restricted section.");
        }
        freeZoneOpen = true;
      } else if (type == RouteInstructionInstructionType.END_FREE_ZONE) {
        if (!freeZoneOpen) {
          throw new ServiceException("END FREE ZONE requires a preceding BEGIN FREE ZONE.");
        }
        freeZoneOpen = false;
      } else if (type == RouteInstructionInstructionType.BEGIN_TRANSIT) {
        if (freeZoneOpen || transitOpen) {
          throw new ServiceException("A transit section cannot begin inside another restricted section.");
        }
        transitOpen = true;
      } else if (type == RouteInstructionInstructionType.END_TRANSIT) {
        if (!transitOpen) {
          throw new ServiceException("END TRANSIT requires a preceding BEGIN TRANSIT.");
        }
        if (instruction.getTransitDurationMillis() == null
            || instruction.getTransitDurationMillis() < 0) {
          throw new ServiceException("END TRANSIT requires a transit duration before publishing.");
        }
        transitOpen = false;
      }
    }
    if (freeZoneOpen) {
      throw new ServiceException("Every BEGIN FREE ZONE requires an END FREE ZONE before publishing.");
    }
    if (transitOpen) {
      throw new ServiceException("Every BEGIN TRANSIT requires an END TRANSIT before publishing.");
    }
  }

  private static void requirePassword(String eventPassword) throws ServiceException {
    if (eventPassword == null || eventPassword.isBlank()) {
      throw new ServiceException("An event password is required to publish a route.");
    }
  }

  private static void applyDefaults(RallyConfigurationEntity configuration) {
    configuration.setScoringUnit(RallyConfigurationScoringUnit.SECONDS);
    configuration.setTimeZone("America/New_York");
    configuration.setCheckpointAcquisitionRadiusMeters(150.0);
    configuration.setCarStartIntervalMillis(60_000L);
  }

  private static String digest(String token) {
    try {
      return Base64.getUrlEncoder().withoutPadding().encodeToString(
          MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException ex) {
      throw new IllegalStateException("SHA-256 must be available", ex);
    }
  }
}
