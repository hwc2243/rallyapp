package com.rallyapp.rallymaster.controller;

import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.service.CheckpointService;
import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.RouteInstructionService;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;
import java.util.Collection;
import java.util.Comparator;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.server.ResponseStatusException;

/** Browser workflow for planning routes belonging to the selected organization. */
@Controller
@RequestMapping("/rally/{rallyId}/routes")
public class RouteController {
  private final RallyService rallyService;
  private final RouteService routeService;
  private final RouteInstructionService routeInstructionService;
  private final CheckpointService checkpointService;

  public RouteController(
      RallyService rallyService,
      RouteService routeService,
      RouteInstructionService routeInstructionService,
      CheckpointService checkpointService) {
    this.rallyService = rallyService;
    this.routeService = routeService;
    this.routeInstructionService = routeInstructionService;
    this.checkpointService = checkpointService;
  }

  @GetMapping
  public String listRoutes(@PathVariable Long rallyId, ModelMap model) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    model.put("rally", rally);
    model.put("routes", routeService.findByRallyId(rallyId));
    return "route/list";
  }

  @GetMapping("/new")
  public String newRoute(@PathVariable Long rallyId, ModelMap model) throws ServiceException {
    model.put("rally", rally(rallyId));
    model.put("route", new RouteDTO());
    return "route/form";
  }

  @PostMapping
  public String createRoute(
      @PathVariable Long rallyId,
      @ModelAttribute("route") RouteDTO route,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    validateRoute(route, bindingResult);
    if (bindingResult.hasErrors()) {
      model.put("rally", rally);
      return "route/form";
    }
    route.setName(route.getName().trim());
    route.setOrganizationId(currentOrganizationId());
    route.setRallyId(rallyId);
    route.setStatus(RouteStatus.PLAN);
    RouteDTO created = routeService.create(route);
    return "redirect:/rally/" + rallyId + "/routes/" + created.getId();
  }

  @GetMapping("/{routeId}")
  public String listItems(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    RouteDTO route = route(rallyId, routeId);
    model.put("rally", rally);
    model.put("route", route);
    model.put("items", orderedItems(routeId));
    return "route/items";
  }

  @GetMapping("/{routeId}/items/new")
  public String chooseItemType(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    return "route/item-choice";
  }

  @GetMapping("/{routeId}/items/nri/new")
  public String newInstruction(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    model.put("routeInstruction", new RouteInstructionDTO());
    return "route/nri-form";
  }

  @PostMapping("/{routeId}/items/nri")
  public String createInstruction(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @ModelAttribute("routeInstruction") RouteInstructionDTO instruction,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    route(rallyId, routeId);
    validateInstruction(instruction, bindingResult);
    if (bindingResult.hasErrors()) {
      populateRoute(model, rallyId, routeId);
      return "route/nri-form";
    }
    if (instruction.getId() == null) {
      applyNewItemContext(instruction, routeId);
      instruction.setItemType(RouteItemItemType.NRI);
      instruction.setInstructionNumber(nextInstructionNumber(routeId));
      routeInstructionService.create(instruction);
    } else {
      RouteInstructionDTO existing = instruction(routeId, instruction.getId());
      applyExistingItemContext(instruction, existing, routeId);
      routeInstructionService.update(instruction);
    }
    return redirectToItems(rallyId, routeId);
  }

  @GetMapping("/{routeId}/items/nri/{itemId}/edit")
  public String editInstruction(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long itemId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    model.put("routeInstruction", instruction(routeId, itemId));
    return "route/nri-form";
  }

  @GetMapping("/{routeId}/items/checkpoint/new")
  public String newCheckpoint(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    model.put("checkpoint", new CheckpointDTO());
    model.put("checkpointTypes", CheckpointCheckpointType.values());
    return "route/checkpoint-form";
  }

  @PostMapping("/{routeId}/items/checkpoint")
  public String createCheckpoint(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @ModelAttribute("checkpoint") CheckpointDTO checkpoint,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    route(rallyId, routeId);
    validateCheckpoint(checkpoint, bindingResult);
    if (bindingResult.hasErrors()) {
      populateCheckpointForm(model, rallyId, routeId);
      return "route/checkpoint-form";
    }
    if (checkpoint.getId() == null) {
      applyNewItemContext(checkpoint, routeId);
      checkpoint.setItemType(RouteItemItemType.CHECKPOINT);
      checkpoint.setCheckpointNumber(nextCheckpointNumber(routeId));
      checkpointService.create(checkpoint);
    } else {
      CheckpointDTO existing = checkpoint(routeId, checkpoint.getId());
      applyExistingItemContext(checkpoint, existing, routeId);
      checkpointService.update(checkpoint);
    }
    return redirectToItems(rallyId, routeId);
  }

  @GetMapping("/{routeId}/items/checkpoint/{itemId}/edit")
  public String editCheckpoint(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long itemId,
      ModelMap model) throws ServiceException {
    populateCheckpointForm(model, rallyId, routeId);
    model.put("checkpoint", checkpoint(routeId, itemId));
    return "route/checkpoint-form";
  }

  private RallyDTO rally(Long rallyId) throws ServiceException {
    RallyDTO rally = rallyService.get(rallyId);
    if (rally == null) throw notFound("Rally");
    return rally;
  }

  private RouteDTO route(Long rallyId, Long routeId) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    RouteDTO route = routeService.get(routeId);
    if (route == null || !rally.getId().equals(route.getRallyId())) throw notFound("Route");
    return route;
  }

  private RouteInstructionDTO instruction(Long routeId, Long itemId) throws ServiceException {
    RouteInstructionDTO instruction = routeInstructionService.get(itemId);
    if (instruction == null || !routeId.equals(instruction.getRouteId())) throw notFound("Route instruction");
    return instruction;
  }

  private CheckpointDTO checkpoint(Long routeId, Long itemId) throws ServiceException {
    CheckpointDTO checkpoint = checkpointService.get(itemId);
    if (checkpoint == null || !routeId.equals(checkpoint.getRouteId())) throw notFound("Checkpoint");
    return checkpoint;
  }

  private Collection<RouteItemDTO> orderedItems(Long routeId) throws ServiceException {
    return routeService.getItems(routeId).stream()
        .sorted(Comparator.comparing(RouteItemDTO::getPosition, Comparator.nullsLast(Comparator.naturalOrder())))
        .toList();
  }

  private void populateRoute(ModelMap model, Long rallyId, Long routeId) throws ServiceException {
    model.put("rally", rally(rallyId));
    model.put("route", route(rallyId, routeId));
  }

  private void populateCheckpointForm(ModelMap model, Long rallyId, Long routeId) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    model.put("checkpointTypes", CheckpointCheckpointType.values());
  }

  private void applyNewItemContext(RouteItemDTO item, Long routeId) throws ServiceException {
    item.setRouteId(routeId);
    item.setOrganizationId(currentOrganizationId());
    item.setPosition(nextPosition(routeId));
    item.setDeleted(false);
  }

  private void applyExistingItemContext(
      RouteItemDTO item, RouteItemDTO existing, Long routeId) {
    item.setRouteId(routeId);
    item.setOrganizationId(currentOrganizationId());
    item.setPosition(existing.getPosition());
    item.setDeleted(existing.getDeleted());
    item.setItemType(existing.getItemType());
    if (item instanceof RouteInstructionDTO instruction
        && existing instanceof RouteInstructionDTO existingInstruction) {
      instruction.setInstructionNumber(existingInstruction.getInstructionNumber());
    }
    if (item instanceof CheckpointDTO checkpoint && existing instanceof CheckpointDTO existingCheckpoint) {
      checkpoint.setCheckpointNumber(existingCheckpoint.getCheckpointNumber());
    }
  }

  private Long nextPosition(Long routeId) throws ServiceException {
    return orderedItems(routeId).stream()
        .map(RouteItemDTO::getPosition)
        .filter(position -> position != null)
        .max(Long::compareTo)
        .orElse(0L) + 1;
  }

  private Long nextInstructionNumber(Long routeId) throws ServiceException {
    return orderedItems(routeId).stream()
        .filter(RouteInstructionDTO.class::isInstance)
        .map(RouteInstructionDTO.class::cast)
        .map(RouteInstructionDTO::getInstructionNumber)
        .filter(number -> number != null)
        .max(Long::compareTo)
        .orElse(0L) + 1;
  }

  private Long nextCheckpointNumber(Long routeId) throws ServiceException {
    return orderedItems(routeId).stream()
        .filter(CheckpointDTO.class::isInstance)
        .map(CheckpointDTO.class::cast)
        .map(CheckpointDTO::getCheckpointNumber)
        .filter(number -> number != null)
        .max(Long::compareTo)
        .orElse(0L) + 1;
  }

  private Long currentOrganizationId() {
    if (SessionContext.getCurrentOrganization() == null) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Select an organization first.");
    }
    return SessionContext.getCurrentOrganization().getId();
  }

  private static String redirectToItems(Long rallyId, Long routeId) {
    return "redirect:/rally/" + rallyId + "/routes/" + routeId;
  }

  private static ResponseStatusException notFound(String type) {
    return new ResponseStatusException(HttpStatus.NOT_FOUND, type + " was not found.");
  }

  private static void validateRoute(RouteDTO route, BindingResult bindingResult) {
    if (blank(route.getName())) bindingResult.rejectValue("name", "required", "A route name is required.");
  }

  private static void validateInstruction(RouteInstructionDTO item, BindingResult bindingResult) {
    validateDistance(item, bindingResult);
    validateOptionalCoordinates(item, bindingResult);
  }

  private static void validateCheckpoint(CheckpointDTO item, BindingResult bindingResult) {
    validateDistance(item, bindingResult);
    if (item.getLatitude() == null) bindingResult.rejectValue("latitude", "required", "Latitude is required.");
    if (item.getLongitude() == null) bindingResult.rejectValue("longitude", "required", "Longitude is required.");
    validateCoordinateRanges(item, bindingResult);
    if (item.getCheckpointType() == null) {
      bindingResult.rejectValue("checkpointType", "required", "A checkpoint type is required.");
    }
  }

  private static void validateDistance(RouteItemDTO item, BindingResult bindingResult) {
    if (item.getDistance() == null) {
      bindingResult.rejectValue("distance", "required", "Mileage is required.");
    } else if (item.getDistance() < 0) {
      bindingResult.rejectValue("distance", "invalid", "Mileage cannot be negative.");
    }
  }

  private static void validateOptionalCoordinates(RouteItemDTO item, BindingResult bindingResult) {
    if (item.getLatitude() != null || item.getLongitude() != null) {
      if (item.getLatitude() == null) bindingResult.rejectValue("latitude", "required", "Latitude is required when longitude is supplied.");
      if (item.getLongitude() == null) bindingResult.rejectValue("longitude", "required", "Longitude is required when latitude is supplied.");
    }
    validateCoordinateRanges(item, bindingResult);
  }

  private static void validateCoordinateRanges(RouteItemDTO item, BindingResult bindingResult) {
    if (item.getLatitude() != null && (item.getLatitude() < -90 || item.getLatitude() > 90)) {
      bindingResult.rejectValue("latitude", "invalid", "Latitude must be between -90 and 90.");
    }
    if (item.getLongitude() != null && (item.getLongitude() < -180 || item.getLongitude() > 180)) {
      bindingResult.rejectValue("longitude", "invalid", "Longitude must be between -180 and 180.");
    }
  }

  private static boolean blank(String value) {
    return value == null || value.isBlank();
  }
}
