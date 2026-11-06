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

import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;

import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRest;

public abstract class BaseExternalRouteRestImpl implements BaseExternalRouteRest
{
	@Autowired
	protected RouteService routeService;

	@PostMapping
	@Override
	public ResponseEntity<RouteDTO> createRoute (@RequestBody RouteDTO route)
	{
	  RouteDTO newRoute = null;
	  
	  try
	  {
	    newRoute = routeService.create(route);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }	
	  
	  return ResponseEntity.status(HttpStatus.CREATED).body(newRoute);
	}
	
	@DeleteMapping("/{id}")
	@Override
    public ResponseEntity<Void> deleteRoute(@PathVariable Long id)
    {
      try
      {
        routeService.delete(id);
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
	public ResponseEntity<RouteDTO> getRoute (@PathVariable Long id)
	{
		RouteDTO route = null;
		
		try	{
			route = routeService.get(id);
		}
		catch (ServiceException ex) {
			ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
		}
		
        if (route != null) {
            return ResponseEntity.ok(route);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping
    @Override
    public ResponseEntity<List<RouteDTO>> listRoutes ()
    {
        try
        {
        List<RouteDTO> routes = routeService.findAll();
        	return ResponseEntity.ok(routes);
        }
        catch (ServiceException ex)
        {
          ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/search")
    @Override  
	public ResponseEntity<List<RouteDTO>> searchRoutes (
	)
	{
	  try
	  {
	    List<RouteDTO> allRoutes = routeService.findAll();
	    List<RouteDTO> filteredRoutes = allRoutes.stream()
          .collect(Collectors.toList());
          
        return ResponseEntity.ok(filteredRoutes);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }
	}

    @GetMapping("/{routeId}/items")
    @Override
    public ResponseEntity<Collection<RouteItemDTO>> listRouteItems(
        @PathVariable Long routeId)
    {
      try
      {
        Collection<RouteItemDTO> values = routeService.getItems(routeId);
        if (values == null)
        {
          return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(values);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
    }
	
    @PutMapping("/{id}")
    @Override
	    public ResponseEntity<RouteDTO> updateRoute(@PathVariable Long id, @RequestBody RouteDTO route)
    {
	      RouteDTO updatedRoute = null;

      if (route.getId() == 0) 
      {
      	route.setId(id);
      }
      else if (id != route.getId())
      {
        return ResponseEntity.badRequest().build();
      }
      try
      {
        RouteDTO existingRoute = routeService.get(id);
        if (existingRoute == null)
        {
          return ResponseEntity.notFound().build();
        }
        updatedRoute = routeService.update(route);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.ok(updatedRoute);
    }
}
