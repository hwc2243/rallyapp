package com.rallyapp.rallymaster.competition;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

interface CompetitionAuthenticationTokenRepository extends JpaRepository<CompetitionAuthenticationTokenEntity, Long> {
  Optional<CompetitionAuthenticationTokenEntity> findByTokenHash(String tokenHash);
}
