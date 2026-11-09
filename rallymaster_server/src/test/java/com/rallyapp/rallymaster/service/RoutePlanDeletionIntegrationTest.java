package com.rallyapp.rallymaster.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RoutePlanDTO;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.CheckpointPersistence;
import com.rallyapp.rallymaster.persistence.RouteInstructionPersistence;
import com.rallyapp.rallymaster.spring.SessionContext;
import java.time.LocalDate;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class RoutePlanDeletionIntegrationTest {

  @Autowired
  private OrganizationService organizationService;
  @Autowired
  private RallyService rallyService;
  @Autowired
  private RouteService routeService;
  @Autowired
  private RouteInstructionService routeInstructionService;
  @Autowired
  private CheckpointService checkpointService;
  @Autowired
  private RouteInstructionPersistence routeInstructionPersistence;
  @Autowired
  private CheckpointPersistence checkpointPersistence;

  @AfterEach
  void clearSessionContext() {
    SessionContext.clear();
  }

  @Test
  void savePlanDeletesOmittedPersistedInstructionsAndCheckpoints() throws Exception {
    OrganizationDTO organization = new OrganizationDTO();
    organization.setName("Deletion test organization");
    organization = organizationService.create(organization);
    SessionContext.setCurrentOrganization(organization);

    RallyDTO rally = new RallyDTO();
    rally.setName("Deletion test rally");
    rally.setDate(LocalDate.now());
    rally.setOrganizationId(organization.getId());
    rally = rallyService.create(rally);

    RouteDTO route = new RouteDTO();
    route.setName("Deletion test route");
    route.setOrganizationId(organization.getId());
    route.setRallyId(rally.getId());
    route.setStatus(RouteStatus.PLAN);
    route = routeService.create(route);

    RouteInstructionDTO instruction = new RouteInstructionDTO();
    instruction.setItemType(RouteItemItemType.NRI);
    instruction.setPosition(1L);
    instruction.setInstructionNumber(1L);
    instruction.setInstructionText("Turn right");
    instruction.setOrganizationId(organization.getId());
    instruction.setRouteId(route.getId());
    instruction = routeInstructionService.create(instruction);

    CheckpointDTO checkpoint = new CheckpointDTO();
    checkpoint.setItemType(RouteItemItemType.CHECKPOINT);
    checkpoint.setPosition(2L);
    checkpoint.setCheckpointNumber(1L);
    checkpoint.setCheckpointType(CheckpointCheckpointType.START);
    checkpoint.setOrganizationId(organization.getId());
    checkpoint.setRouteId(route.getId());
    checkpoint = checkpointService.create(checkpoint);

    assertEquals(1, routeInstructionPersistence.findAllForRoute(route.getId()).size());
    assertEquals(1, checkpointPersistence.findAllForRoute(route.getId()).size());

    routeService.savePlan(route.getId(), new RoutePlanDTO());

    assertNull(routeInstructionService.get(instruction.getId()));
    assertNull(checkpointService.get(checkpoint.getId()));
  }
}
