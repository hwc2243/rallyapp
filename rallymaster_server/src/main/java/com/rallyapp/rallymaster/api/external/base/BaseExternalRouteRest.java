package com.rallyapp.rallymaster.api.external.base;

import java.util.Collection;
import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRest;

public interface BaseExternalRouteRest
{
	public ResponseEntity<RouteDTO> createRoute (RouteDTO route);
	
    public ResponseEntity<Void> deleteRoute(Long id);

	public ResponseEntity<RouteDTO> getRoute (Long id);
	
	public ResponseEntity<List<RouteDTO>> listRoutes ();
	
	public ResponseEntity<List<RouteDTO>> searchRoutes (
	);

	public ResponseEntity<Collection<RouteItemDTO>> listRouteItems (
		Long routeId);
	
	    public ResponseEntity<RouteDTO> updateRoute (Long id, RouteDTO route);
}
