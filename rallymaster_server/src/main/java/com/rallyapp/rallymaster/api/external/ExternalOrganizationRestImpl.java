package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationRestImpl;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;

@RestController
@RequestMapping("/api/external/organization")
public class ExternalOrganizationRestImpl
   extends BaseExternalOrganizationRestImpl
   implements ExternalOrganizationRest
{
    @PostMapping
    @Override
    public ResponseEntity<OrganizationDTO> createOrganization(
        @RequestBody OrganizationDTO organization) {
      UserDTO currentUser = SessionContext.getCurrentUser();
      if (currentUser == null || currentUser.getId() == null) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }

      try {
        OrganizationDTO createdOrganization = organizationService.createOrganizationFor(
            currentUser, organization);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdOrganization);
      } catch (ServiceException ex) {
        throw new IllegalStateException("Unable to create organization.", ex);
      }
    }
}
