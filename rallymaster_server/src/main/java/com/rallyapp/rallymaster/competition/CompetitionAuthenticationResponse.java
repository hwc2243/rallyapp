package com.rallyapp.rallymaster.competition;

import java.time.Instant;

public record CompetitionAuthenticationResponse(String registrationToken, Instant expiresAt) {
}
