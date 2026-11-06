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

import com.rallyapp.rallymaster.dto.RouteInstructionDTO;

import com.rallyapp.rallymaster.service.RouteInstructionService;
import com.rallyapp.rallymaster.service.ServiceException;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteInstructionRest;

public abstract class BaseExternalRouteInstructionRestImpl implements BaseExternalRouteInstructionRest
{
	@Autowired
	protected RouteInstructionService routeInstructionService;

	@PostMapping
	@Override
	public ResponseEntity<RouteInstructionDTO> createRouteInstruction (@RequestBody RouteInstructionDTO routeInstruction)
	{
	  RouteInstructionDTO newRouteInstruction = null;
	  
	  try
	  {
	    newRouteInstruction = routeInstructionService.create(routeInstruction);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }	
	  
	  return ResponseEntity.status(HttpStatus.CREATED).body(newRouteInstruction);
	}
	
	@DeleteMapping("/{id}")
	@Override
    public ResponseEntity<Void> deleteRouteInstruction(@PathVariable Long id)
    {
      try
      {
        routeInstructionService.delete(id);
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
	public ResponseEntity<RouteInstructionDTO> getRouteInstruction (@PathVariable Long id)
	{
		RouteInstructionDTO routeInstruction = null;
		
		try	{
			routeInstruction = routeInstructionService.get(id);
		}
		catch (ServiceException ex) {
			ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
		}
		
        if (routeInstruction != null) {
            return ResponseEntity.ok(routeInstruction);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping
    @Override
    public ResponseEntity<List<RouteInstructionDTO>> listRouteInstructions ()
    {
        try
        {
        List<RouteInstructionDTO> routeInstructions = routeInstructionService.findAll();
        	return ResponseEntity.ok(routeInstructions);
        }
        catch (ServiceException ex)
        {
          ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/search")
    @Override  
	public ResponseEntity<List<RouteInstructionDTO>> searchRouteInstructions (
	)
	{
	  try
	  {
	    List<RouteInstructionDTO> allRouteInstructions = routeInstructionService.findAll();
	    List<RouteInstructionDTO> filteredRouteInstructions = allRouteInstructions.stream()
          .collect(Collectors.toList());
          
        return ResponseEntity.ok(filteredRouteInstructions);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }
	}

	
    @PutMapping("/{id}")
    @Override
	    public ResponseEntity<RouteInstructionDTO> updateRouteInstruction(@PathVariable Long id, @RequestBody RouteInstructionDTO routeInstruction)
    {
	      RouteInstructionDTO updatedRouteInstruction = null;

      if (routeInstruction.getId() == 0) 
      {
      	routeInstruction.setId(id);
      }
      else if (id != routeInstruction.getId())
      {
        return ResponseEntity.badRequest().build();
      }
      try
      {
        RouteInstructionDTO existingRouteInstruction = routeInstructionService.get(id);
        if (existingRouteInstruction == null)
        {
          return ResponseEntity.notFound().build();
        }
        updatedRouteInstruction = routeInstructionService.update(routeInstruction);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.ok(updatedRouteInstruction);
    }
}
