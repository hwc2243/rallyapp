package com.rallyapp.rallymaster.api.external.base;

import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.RallyDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRest;

public interface BaseExternalRallyRest
{
	public ResponseEntity<RallyDTO> createRally (RallyDTO rally);
	
    public ResponseEntity<Void> deleteRally(Long id);

	public ResponseEntity<RallyDTO> getRally (Long id);
	
	public ResponseEntity<List<RallyDTO>> listRallys ();
	
	public ResponseEntity<List<RallyDTO>> searchRallys (
	);
	
	    public ResponseEntity<RallyDTO> updateRally (Long id, RallyDTO rally);
}
