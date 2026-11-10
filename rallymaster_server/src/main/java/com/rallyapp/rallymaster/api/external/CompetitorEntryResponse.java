package com.rallyapp.rallymaster.api.external;

/** A rallymaster-facing summary of one registered competitor team. */
public record CompetitorEntryResponse(
    Long entryId,
    Long carNumber,
    String driverFirstName,
    String driverLastName,
    String navigatorFirstName,
    String navigatorLastName) {}
