package com.rallyapp.rallymaster.api.external.base;

import java.util.Collection;
import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.CheckpointDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalCheckpointRest;

public interface BaseExternalCheckpointRest
{
	public ResponseEntity<CheckpointDTO> createCheckpoint (CheckpointDTO checkpoint);
	
    public ResponseEntity<Void> deleteCheckpoint(Long id);

	public ResponseEntity<CheckpointDTO> getCheckpoint (Long id);
	
	public ResponseEntity<List<CheckpointDTO>> listCheckpoints ();
	
	public ResponseEntity<List<CheckpointDTO>> searchCheckpoints (
	);

	
	    public ResponseEntity<CheckpointDTO> updateCheckpoint (Long id, CheckpointDTO checkpoint);
}
