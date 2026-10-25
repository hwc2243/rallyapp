package com.rallyapp.rallymaster.api.external;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.OrganizationService;
import com.rallyapp.rallymaster.spring.SessionContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.Mockito.mock;

class ExternalOrganizationRestImplTest {

  @AfterEach
  void clearSessionContext() {
    SessionContext.clear();
  }

  @Test
  void createOrganizationMakesTheCurrentUserAnAdmin() throws Exception {
    OrganizationService organizationService = mock(OrganizationService.class);
    ExternalOrganizationRestImpl controller = controller(organizationService);
    UserDTO user = new UserDTO();
    user.setId(4L);
    OrganizationDTO request = new OrganizationDTO();
    request.setName("Fall Color Rally");
    OrganizationDTO created = new OrganizationDTO();
    created.setId(9L);
    created.setName(request.getName());
    SessionContext.setCurrentUser(user);
    when(organizationService.createOrganizationFor(user, request)).thenReturn(created);

    var response = controller.createOrganization(request);

    assertEquals(HttpStatus.CREATED, response.getStatusCode());
    assertEquals(created, response.getBody());
    verify(organizationService).createOrganizationFor(user, request);
  }

  @Test
  void createOrganizationRejectsARequestWithoutAnApplicationUser() {
    OrganizationService organizationService = mock(OrganizationService.class);
    ExternalOrganizationRestImpl controller = controller(organizationService);

    var response = controller.createOrganization(new OrganizationDTO());

    assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    verifyNoInteractions(organizationService);
  }

  private ExternalOrganizationRestImpl controller(OrganizationService organizationService) {
    ExternalOrganizationRestImpl controller = new ExternalOrganizationRestImpl();
    ReflectionTestUtils.setField(controller, "organizationService", organizationService);
    return controller;
  }
}
