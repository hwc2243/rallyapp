package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationMembershipRestImpl;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.spring.SessionContext;

@RestController
@RequestMapping("/api/external/organizationMembership")
public class ExternalOrganizationMembershipRestImpl
   extends BaseExternalOrganizationMembershipRestImpl
   implements ExternalOrganizationMembershipRest
{
	@GetMapping("/me")
	public ResponseEntity<OrganizationMembershipDTO> me ()
    {
		OrganizationMembershipDTO membership =
				this.organizationMembershipService.fetchByOrganizationIdAndUserId(SessionContext.getCurrentUser().getId());

		if (membership == null) {
			return ResponseEntity.notFound().build();
		}

		return ResponseEntity.ok(membership);
    }
}
