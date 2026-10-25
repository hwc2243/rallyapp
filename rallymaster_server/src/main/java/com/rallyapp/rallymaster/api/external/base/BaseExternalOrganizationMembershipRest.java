package com.rallyapp.rallymaster.api.external.base;

import java.util.List;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.RequestParam;

import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationMembershipRest;

public interface BaseExternalOrganizationMembershipRest
{
	public ResponseEntity<OrganizationMembershipDTO> createOrganizationMembership (OrganizationMembershipDTO organizationMembership);
	
    public ResponseEntity<Void> deleteOrganizationMembership(Long id);

	public ResponseEntity<OrganizationMembershipDTO> getOrganizationMembership (Long id);
	
	public ResponseEntity<List<OrganizationMembershipDTO>> listOrganizationMemberships ();
	
	public ResponseEntity<List<OrganizationMembershipDTO>> searchOrganizationMemberships (
	);
	
	    public ResponseEntity<OrganizationMembershipDTO> updateOrganizationMembership (Long id, OrganizationMembershipDTO organizationMembership);
}
