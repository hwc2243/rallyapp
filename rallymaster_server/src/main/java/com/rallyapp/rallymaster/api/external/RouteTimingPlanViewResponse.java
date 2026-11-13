package com.rallyapp.rallymaster.api.external;

import java.util.List;

/** Read-only organizer view of a calculated route timing plan. */
public record RouteTimingPlanViewResponse(Long version, List<RouteTimingPointViewResponse> points) {}
