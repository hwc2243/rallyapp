package com.rallyapp.rallymaster.api.external;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.OrganizationMembershipService;
import com.rallyapp.rallymaster.spring.SessionContext;

@RestController
@RequestMapping("/api/external/me")
public class MeRestImpl {

	@Autowired
	protected OrganizationMembershipService organizationMembershipService;
	
	@GetMapping
	public ResponseEntity<UserDTO> me ()
    {
		return ResponseEntity.ok(SessionContext.getCurrentUser());
    }
	
	@GetMapping("/mine")
	public ResponseEntity<List<OrganizationDTO>> mine ()
	{
		return ResponseEntity.ok(organizationMembershipService.findOrganizationsByUser(SessionContext.getCurrentUser()));
	}
}
