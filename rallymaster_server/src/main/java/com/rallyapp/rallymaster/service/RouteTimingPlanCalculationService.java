package com.rallyapp.rallymaster.service;

import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;

/** Calculates and persists the authoritative car-zero timing plan for a route. */
public interface RouteTimingPlanCalculationService {
  RouteTimingPlanDTO calculateForRoute(Long routeId) throws ServiceException;
}
