package com.rallyapp.rallymaster.api.compete;

/** Password proof for a single discovered RallyMaster rally. */
public record CompetitionAuthenticationRequest(Long rallyId, String password) {
}
