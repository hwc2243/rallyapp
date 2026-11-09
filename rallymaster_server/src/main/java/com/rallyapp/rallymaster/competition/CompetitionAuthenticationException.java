package com.rallyapp.rallymaster.competition;

/** Deliberately carries no detail that could reveal event/password validity. */
public class CompetitionAuthenticationException extends RuntimeException {
  public CompetitionAuthenticationException() {
    super("Competition authentication failed");
  }
}
