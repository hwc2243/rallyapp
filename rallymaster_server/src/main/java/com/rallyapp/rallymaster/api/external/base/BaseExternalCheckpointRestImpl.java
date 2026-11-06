package com.rallyapp.rallymaster.api.external.base;

import java.util.Collection;
import java.util.List;
import java.util.ArrayList;

import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.CheckpointDTO;

import com.rallyapp.rallymaster.service.CheckpointService;
import com.rallyapp.rallymaster.service.ServiceException;

import com.rallyapp.rallymaster.api.external.base.BaseExternalCheckpointRest;

public abstract class BaseExternalCheckpointRestImpl implements BaseExternalCheckpointRest
{
	@Autowired
	protected CheckpointService checkpointService;

	@PostMapping
	@Override
	public ResponseEntity<CheckpointDTO> createCheckpoint (@RequestBody CheckpointDTO checkpoint)
	{
	  CheckpointDTO newCheckpoint = null;
	  
	  try
	  {
	    newCheckpoint = checkpointService.create(checkpoint);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }	
	  
	  return ResponseEntity.status(HttpStatus.CREATED).body(newCheckpoint);
	}
	
	@DeleteMapping("/{id}")
	@Override
    public ResponseEntity<Void> deleteCheckpoint(@PathVariable Long id)
    {
      try
      {
        checkpointService.delete(id);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.noContent().build();
    }

	@GetMapping("/{id}")
	@Override
	public ResponseEntity<CheckpointDTO> getCheckpoint (@PathVariable Long id)
	{
		CheckpointDTO checkpoint = null;
		
		try	{
			checkpoint = checkpointService.get(id);
		}
		catch (ServiceException ex) {
			ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
		}
		
        if (checkpoint != null) {
            return ResponseEntity.ok(checkpoint);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping
    @Override
    public ResponseEntity<List<CheckpointDTO>> listCheckpoints ()
    {
        try
        {
        List<CheckpointDTO> checkpoints = checkpointService.findAll();
        	return ResponseEntity.ok(checkpoints);
        }
        catch (ServiceException ex)
        {
          ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/search")
    @Override  
	public ResponseEntity<List<CheckpointDTO>> searchCheckpoints (
	)
	{
	  try
	  {
	    List<CheckpointDTO> allCheckpoints = checkpointService.findAll();
	    List<CheckpointDTO> filteredCheckpoints = allCheckpoints.stream()
          .collect(Collectors.toList());
          
        return ResponseEntity.ok(filteredCheckpoints);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }
	}

	
    @PutMapping("/{id}")
    @Override
	    public ResponseEntity<CheckpointDTO> updateCheckpoint(@PathVariable Long id, @RequestBody CheckpointDTO checkpoint)
    {
	      CheckpointDTO updatedCheckpoint = null;

      if (checkpoint.getId() == 0) 
      {
      	checkpoint.setId(id);
      }
      else if (id != checkpoint.getId())
      {
        return ResponseEntity.badRequest().build();
      }
      try
      {
        CheckpointDTO existingCheckpoint = checkpointService.get(id);
        if (existingCheckpoint == null)
        {
          return ResponseEntity.notFound().build();
        }
        updatedCheckpoint = checkpointService.update(checkpoint);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.ok(updatedCheckpoint);
    }
}
