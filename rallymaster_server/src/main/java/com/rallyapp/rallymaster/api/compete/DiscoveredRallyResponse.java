package com.rallyapp.rallymaster.api.compete;

import java.time.LocalDate;

/** Safe public rally summary returned before competitor authentication. */
public record DiscoveredRallyResponse(
    Long rallyId,
    String name,
    LocalDate date) {
}
