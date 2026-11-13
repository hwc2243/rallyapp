package com.rallyapp.rallymaster.api.external;

/** One canonical route item and its calculated car-zero arrival time. */
public record RouteTimingPointViewResponse(Long routeItemId, String arrivalTime) {}
