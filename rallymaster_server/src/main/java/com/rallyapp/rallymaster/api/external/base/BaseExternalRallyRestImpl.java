package com.rallyapp.rallymaster.api.external.base;

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

import com.rallyapp.rallymaster.dto.RallyDTO;

import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.ServiceException;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRest;

public abstract class BaseExternalRallyRestImpl implements BaseExternalRallyRest
{
	@Autowired
	protected RallyService rallyService;

	@PostMapping
	@Override
	public ResponseEntity<RallyDTO> createRally (@RequestBody RallyDTO rally)
	{
	  RallyDTO newRally = null;
	  
	  try
	  {
	    newRally = rallyService.create(rally);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }	
	  
	  return ResponseEntity.status(HttpStatus.CREATED).body(newRally);
	}
	
	@DeleteMapping("/{id}")
	@Override
    public ResponseEntity<Void> deleteRally(@PathVariable Long id)
    {
      try
      {
        rallyService.delete(id);
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
	public ResponseEntity<RallyDTO> getRally (@PathVariable Long id)
	{
		RallyDTO rally = null;
		
		try	{
			rally = rallyService.get(id);
		}
		catch (ServiceException ex) {
			ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
		}
		
        if (rally != null) {
            return ResponseEntity.ok(rally);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping
    @Override
    public ResponseEntity<List<RallyDTO>> listRallys ()
    {
        try
        {
        List<RallyDTO> rallys = rallyService.findAll();
        	return ResponseEntity.ok(rallys);
        }
        catch (ServiceException ex)
        {
          ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/search")
    @Override  
	public ResponseEntity<List<RallyDTO>> searchRallys (
	)
	{
	  try
	  {
	    List<RallyDTO> allRallys = rallyService.findAll();
	    List<RallyDTO> filteredRallys = allRallys.stream()
          .collect(Collectors.toList());
          
        return ResponseEntity.ok(filteredRallys);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }
	}
	
    @PutMapping("/{id}")
    @Override
	    public ResponseEntity<RallyDTO> updateRally(@PathVariable Long id, @RequestBody RallyDTO rally)
    {
	      RallyDTO updatedRally = null;

      if (rally.getId() == 0) 
      {
      	rally.setId(id);
      }
      else if (id != rally.getId())
      {
        return ResponseEntity.badRequest().build();
      }
      try
      {
        RallyDTO existingRally = rallyService.get(id);
        if (existingRally == null)
        {
          return ResponseEntity.notFound().build();
        }
        updatedRally = rallyService.update(rally);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.ok(updatedRally);
    }
}
