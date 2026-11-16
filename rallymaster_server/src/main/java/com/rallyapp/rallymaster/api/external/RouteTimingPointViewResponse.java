package com.rallyapp.rallymaster.api.external;

/** One canonical route item, its arrival time, and the speed used for its leg. */
public record RouteTimingPointViewResponse(Long routeItemId, String arrivalTime, Double speed) {}
