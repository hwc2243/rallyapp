package com.rallyapp.rallymaster.api.external.base;

import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.OrganizationDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationRest;

public interface BaseExternalOrganizationRest
{
	public ResponseEntity<OrganizationDTO> createOrganization (OrganizationDTO organization);
	
    public ResponseEntity<Void> deleteOrganization(Long id);

	public ResponseEntity<OrganizationDTO> getOrganization (Long id);
	
	public ResponseEntity<List<OrganizationDTO>> listOrganizations ();
	
	public ResponseEntity<List<OrganizationDTO>> searchOrganizations (
	);
	
	    public ResponseEntity<OrganizationDTO> updateOrganization (Long id, OrganizationDTO organization);
}
