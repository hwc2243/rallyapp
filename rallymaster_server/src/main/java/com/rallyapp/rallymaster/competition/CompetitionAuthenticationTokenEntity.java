package com.rallyapp.rallymaster.competition;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;

/** Stores only a digest of a short-lived password-proof token. */
@Entity
@Table(name = "competition_authentication_token", indexes = {
    @Index(name = "idx_competition_auth_token_hash", columnList = "token_hash", unique = true),
    @Index(name = "idx_competition_auth_token_rally", columnList = "rally_id")
})
public class CompetitionAuthenticationTokenEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "rally_id", nullable = false)
  private Long rallyId;

  @Column(name = "token_hash", nullable = false, length = 64, unique = true)
  private String tokenHash;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "used_at")
  private Instant usedAt;

  protected CompetitionAuthenticationTokenEntity() {
  }

  CompetitionAuthenticationTokenEntity(Long rallyId, String tokenHash, Instant expiresAt) {
    this.rallyId = rallyId;
    this.tokenHash = tokenHash;
    this.expiresAt = expiresAt;
  }

  boolean isUsableFor(Long expectedRallyId, Instant now) {
    return usedAt == null && rallyId.equals(expectedRallyId) && expiresAt.isAfter(now);
  }

  void markUsed(Instant now) {
    usedAt = now;
  }
}
