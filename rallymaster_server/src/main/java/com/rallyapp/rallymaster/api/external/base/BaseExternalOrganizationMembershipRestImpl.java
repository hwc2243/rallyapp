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

import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;

import com.rallyapp.rallymaster.service.OrganizationMembershipService;
import com.rallyapp.rallymaster.service.ServiceException;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationMembershipRest;

public abstract class BaseExternalOrganizationMembershipRestImpl implements BaseExternalOrganizationMembershipRest
{
	@Autowired
	protected OrganizationMembershipService organizationMembershipService;

	@PostMapping
	@Override
	public ResponseEntity<OrganizationMembershipDTO> createOrganizationMembership (@RequestBody OrganizationMembershipDTO organizationMembership)
	{
	  OrganizationMembershipDTO newOrganizationMembership = null;
	  
	  try
	  {
	    newOrganizationMembership = organizationMembershipService.create(organizationMembership);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }	
	  
	  return ResponseEntity.status(HttpStatus.CREATED).body(newOrganizationMembership);
	}
	
	@DeleteMapping("/{id}")
	@Override
    public ResponseEntity<Void> deleteOrganizationMembership(@PathVariable Long id)
    {
      try
      {
        organizationMembershipService.delete(id);
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
	public ResponseEntity<OrganizationMembershipDTO> getOrganizationMembership (@PathVariable Long id)
	{
		OrganizationMembershipDTO organizationMembership = null;
		
		try	{
			organizationMembership = organizationMembershipService.get(id);
		}
		catch (ServiceException ex) {
			ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
		}
		
        if (organizationMembership != null) {
            return ResponseEntity.ok(organizationMembership);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping
    @Override
    public ResponseEntity<List<OrganizationMembershipDTO>> listOrganizationMemberships ()
    {
        try
        {
        List<OrganizationMembershipDTO> organizationMemberships = organizationMembershipService.findAll();
        	return ResponseEntity.ok(organizationMemberships);
        }
        catch (ServiceException ex)
        {
          ex.printStackTrace();
          return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/search")
    @Override  
	public ResponseEntity<List<OrganizationMembershipDTO>> searchOrganizationMemberships (
	)
	{
	  try
	  {
	    List<OrganizationMembershipDTO> allOrganizationMemberships = organizationMembershipService.findAll();
	    List<OrganizationMembershipDTO> filteredOrganizationMemberships = allOrganizationMemberships.stream()
          .collect(Collectors.toList());
          
        return ResponseEntity.ok(filteredOrganizationMemberships);
	  }
	  catch (ServiceException ex)
	  {
	    ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
	  }
	}
	
    @PutMapping("/{id}")
    @Override
	    public ResponseEntity<OrganizationMembershipDTO> updateOrganizationMembership(@PathVariable Long id, @RequestBody OrganizationMembershipDTO organizationMembership)
    {
	      OrganizationMembershipDTO updatedOrganizationMembership = null;

      if (organizationMembership.getId() == 0) 
      {
      	organizationMembership.setId(id);
      }
      else if (id != organizationMembership.getId())
      {
        return ResponseEntity.badRequest().build();
      }
      try
      {
        OrganizationMembershipDTO existingOrganizationMembership = organizationMembershipService.get(id);
        if (existingOrganizationMembership == null)
        {
          return ResponseEntity.notFound().build();
        }
        updatedOrganizationMembership = organizationMembershipService.update(organizationMembership);
      }
      catch (ServiceException ex)
      {
        ex.printStackTrace();
        return ResponseEntity.internalServerError().build();
      }
      return ResponseEntity.ok(updatedOrganizationMembership);
    }
}
