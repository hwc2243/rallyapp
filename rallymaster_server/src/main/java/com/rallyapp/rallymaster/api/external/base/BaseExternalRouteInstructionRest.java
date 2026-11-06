package com.rallyapp.rallymaster.api.external.base;

import java.util.Collection;
import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.RouteInstructionDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteInstructionRest;

public interface BaseExternalRouteInstructionRest
{
	public ResponseEntity<RouteInstructionDTO> createRouteInstruction (RouteInstructionDTO routeInstruction);
	
    public ResponseEntity<Void> deleteRouteInstruction(Long id);

	public ResponseEntity<RouteInstructionDTO> getRouteInstruction (Long id);
	
	public ResponseEntity<List<RouteInstructionDTO>> listRouteInstructions ();
	
	public ResponseEntity<List<RouteInstructionDTO>> searchRouteInstructions (
	);

	
	    public ResponseEntity<RouteInstructionDTO> updateRouteInstruction (Long id, RouteInstructionDTO routeInstruction);
}
