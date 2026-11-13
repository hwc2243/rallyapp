package com.rallyapp.rallymaster.controller;

import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.service.CheckpointService;
import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.RouteInstructionService;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;
import java.util.Collection;
import java.util.Comparator;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
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
  private final RallyConfigurationPersistence rallyConfigurationPersistence;

  public RouteController(
      RallyService rallyService,
      RouteService routeService,
      RouteInstructionService routeInstructionService,
      CheckpointService checkpointService,
      RallyConfigurationPersistence rallyConfigurationPersistence) {
    this.rallyService = rallyService;
    this.routeService = routeService;
    this.routeInstructionService = routeInstructionService;
    this.checkpointService = checkpointService;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
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
    RallyDTO rally = rally(rallyId);
    RouteDTO route = latestRouteDefaults(rallyId);
    populateRouteForm(model, rally, route, formatStart(route));
    return "route/form";
  }

  @PostMapping
  public String createRoute(
      @PathVariable Long rallyId,
      @ModelAttribute("route") RouteDTO route,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String carZeroStartLocal,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String restartInterval,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String defaultPauseDuration,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    applySchedule(route, carZeroStartLocal, restartInterval, defaultPauseDuration, bindingResult);
    validateRoute(route, bindingResult);
    if (bindingResult.hasErrors()) {
      model.put("rally", rally);
      populateRouteForm(model, rally, route, carZeroStartLocal);
      return "route/form";
    }
    route.setName(route.getName().trim());
    route.setOrganizationId(currentOrganizationId());
    route.setRallyId(rallyId);
    route.setStatus(RouteStatus.PLAN);
    RouteDTO created = routeService.create(route);
    return "redirect:/rally/" + rallyId + "/routes/" + created.getId();
  }

  @GetMapping("/{routeId}/edit")
  public String editRoute(@PathVariable Long rallyId, @PathVariable Long routeId, ModelMap model)
      throws ServiceException {
    RallyDTO rally = rally(rallyId);
    RouteDTO route = route(rallyId, routeId);
    populateRouteForm(model, rally, route, formatStart(route));
    model.put("editing", true);
    model.put("formAction", "/rally/" + rallyId + "/routes/" + routeId);
    return "route/form";
  }

  @PostMapping("/{routeId}")
  public String updateRoute(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @ModelAttribute("route") RouteDTO submitted,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String carZeroStartLocal,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String restartInterval,
      @org.springframework.web.bind.annotation.RequestParam(required = false) String defaultPauseDuration,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    RallyDTO rally = rally(rallyId);
    RouteDTO existing = route(rallyId, routeId);
    if (existing.getStatus() == RouteStatus.ACTIVE || existing.getStatus() == RouteStatus.COMPLETED) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "An active or completed route cannot be changed.");
    }
    submitted.setId(existing.getId());
    submitted.setOrganizationId(existing.getOrganizationId());
    submitted.setRallyId(existing.getRallyId());
    submitted.setStatus(existing.getStatus());
    applySchedule(submitted, carZeroStartLocal, restartInterval, defaultPauseDuration, bindingResult);
    validateRoute(submitted, bindingResult);
    if (bindingResult.hasErrors()) {
      populateRouteForm(model, rally, submitted, carZeroStartLocal);
      model.put("editing", true);
      model.put("formAction", "/rally/" + rallyId + "/routes/" + routeId);
      return "route/form";
    }
    submitted.setName(submitted.getName().trim());
    routeService.update(submitted);
    return "redirect:/rally/" + rallyId + "/routes/" + routeId;
  }

  @PostMapping("/{routeId}/delete")
  public String deleteRoute(@PathVariable Long rallyId, @PathVariable Long routeId)
      throws ServiceException {
    route(rallyId, routeId);
    try {
      routeService.delete(routeId);
    } catch (ServiceException ex) {
      if (ex.getMessage() != null && ex.getMessage().contains("Only planning")) {
        throw new ResponseStatusException(HttpStatus.CONFLICT, ex.getMessage());
      }
      throw ex;
    }
    return "redirect:/rally/" + rallyId + "/routes";
  }

  private RouteDTO latestRouteDefaults(Long rallyId) throws ServiceException {
    return routeService.findByRallyId(rallyId).stream()
        .max(Comparator.comparing(RouteDTO::getId, Comparator.nullsLast(Comparator.naturalOrder())))
        .map(source -> {
          RouteDTO copy = new RouteDTO();
          copy.setDefaultSpeed(source.getDefaultSpeed());
          copy.setRestartIntervalMillis(source.getRestartIntervalMillis());
          copy.setDefaultPauseDurationMillis(source.getDefaultPauseDurationMillis());
          copy.setTimeZone(source.getTimeZone());
          copy.setCarZeroStartEpochMillis(source.getCarZeroStartEpochMillis());
          copy.setMaximumCheckpointScore(source.getMaximumCheckpointScore());
          return copy;
        }).orElseGet(() -> {
          RouteDTO defaults = new RouteDTO();
          defaults.setTimeZone("America/New_York");
          defaults.setRestartIntervalMillis(0L);
          var settings = rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
          if (settings != null) {
            defaults.setDefaultSpeed(settings.getDefaultSpeed());
            defaults.setRestartIntervalMillis(settings.getDefaultRestartIntervalMillis());
            defaults.setDefaultPauseDurationMillis(settings.getDefaultPauseDurationMillis());
          }
          return defaults;
        });
  }

  private void applySchedule(RouteDTO route, String localStart, String restartInterval,
      String defaultPauseDuration, BindingResult errors) {
    if (route.getTimeZone() == null || route.getTimeZone().isBlank()) {
      errors.rejectValue("timeZone", "required", "A time zone is required.");
      return;
    }
    try {
      ZoneId zone = ZoneId.of(route.getTimeZone());
      if (localStart == null || localStart.isBlank()) {
        errors.reject("carZeroStart", "A car-zero start time is required.");
      } else {
        route.setCarZeroStartEpochMillis(LocalDateTime.parse(localStart).atZone(zone).toInstant().toEpochMilli());
      }
    } catch (RuntimeException ex) {
      errors.reject("schedule", "Enter a valid time zone and car-zero start time.");
    }
    applyDuration(restartInterval, "restartInterval", route::setRestartIntervalMillis, errors);
    applyDuration(defaultPauseDuration, "defaultPauseDuration", route::setDefaultPauseDurationMillis, errors);
  }

  private void applyDuration(String value, String field,
      java.util.function.Consumer<Long> target, BindingResult errors) {
    if (value == null || value.isBlank()) {
      target.accept(null);
      return;
    }
    try {
      String[] parts = value.trim().split(":");
      if (parts.length != 2) throw new IllegalArgumentException();
      long minutes = Long.parseLong(parts[0]);
      long seconds = Long.parseLong(parts[1]);
      if (minutes < 0 || seconds < 0 || seconds >= 60) throw new IllegalArgumentException();
      target.accept((minutes * 60 + seconds) * 1000);
    } catch (RuntimeException ex) {
      errors.rejectValue(field, "duration", "Enter a duration as mm:ss.");
    }
  }

  private void populateRouteForm(ModelMap model, RallyDTO rally, RouteDTO route, String localStart) {
    model.put("rally", rally);
    model.put("route", route);
    model.put("carZeroStartLocal", localStart);
    model.put("restartInterval", formatDuration(route.getRestartIntervalMillis()));
    model.put("defaultPauseDuration", formatDuration(route.getDefaultPauseDurationMillis()));
  }

  private String formatDuration(Long millis) {
    if (millis == null) return "";
    long seconds = millis / 1000;
    return "%d:%02d".formatted(seconds / 60, seconds % 60);
  }

  private String formatStart(RouteDTO route) {
    if (route.getCarZeroStartEpochMillis() == null) return "";
    try {
      ZoneId zone = ZoneId.of(route.getTimeZone());
      return LocalDateTime.ofInstant(Instant.ofEpochMilli(route.getCarZeroStartEpochMillis()), zone).toString();
    } catch (RuntimeException ex) {
      return "";
    }
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
    model.put("checkpointAllowed", checkpointAllowed(routeId));
    return "route/item-choice";
  }

  @GetMapping("/{routeId}/items/nri/new")
  public String newInstruction(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    RouteInstructionDTO instruction = new RouteInstructionDTO();
    instruction.setInstructionType(RouteInstructionInstructionType.STANDARD);
    model.put("routeInstruction", instruction);
    model.put("instructionTypes", allowedInstructionTypes(routeId));
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
    if (instruction.getId() == null && !allowedInstructionTypes(routeId).contains(instruction.getInstructionType())) {
      bindingResult.rejectValue("instructionType", "invalid", "That NRI type is not available until the matching begin/end state changes.");
    }
    if (bindingResult.hasErrors()) {
      populateRoute(model, rallyId, routeId);
      model.put("instructionTypes", allowedInstructionTypes(routeId));
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
    model.put("instructionTypes", RouteInstructionInstructionType.values());
    return "route/nri-form";
  }

  @GetMapping("/{routeId}/items/checkpoint/new")
  public String newCheckpoint(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    if (!checkpointAllowed(routeId)) throw new ResponseStatusException(HttpStatus.CONFLICT, "Checkpoints cannot be added while a free zone or transit is open.");
    model.put("checkpoint", new CheckpointDTO());
    model.put("checkpointTypes", availableCheckpointTypes(routeId));
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
    if (checkpoint.getId() == null && !checkpointAllowed(routeId)) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Checkpoints cannot be added while a free zone or transit is open.");
    }
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
    CheckpointDTO checkpoint = checkpoint(routeId, itemId);
    model.put("checkpoint", checkpoint);
    if (checkpoint.getCheckpointType() == CheckpointCheckpointType.START) {
      model.put("checkpointTypes", java.util.List.of(CheckpointCheckpointType.START));
    }
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
    model.put("checkpointTypes", availableCheckpointTypes(routeId));
  }

  private Collection<CheckpointCheckpointType> availableCheckpointTypes(Long routeId) {
    boolean hasStart = !checkpointService
        .findByRouteId(routeId)
        .stream()
        .filter(checkpoint -> !Boolean.TRUE.equals(checkpoint.getDeleted()))
        .filter(checkpoint -> checkpoint.getCheckpointType() == CheckpointCheckpointType.START)
        .toList()
        .isEmpty();
    return java.util.Arrays.stream(CheckpointCheckpointType.values())
        .filter(type -> type != CheckpointCheckpointType.START || !hasStart)
        .toList();
  }

  private Collection<RouteInstructionInstructionType> allowedInstructionTypes(Long routeId) throws ServiceException {
    RouteInstructionInstructionType open = null;
    for (RouteItemDTO item : orderedItems(routeId)) {
      if (!(item instanceof RouteInstructionDTO instruction)) continue;
      RouteInstructionInstructionType type = instruction.getInstructionType();
      if (type == RouteInstructionInstructionType.BEGIN_FREE_ZONE || type == RouteInstructionInstructionType.BEGIN_TRANSIT) open = type;
      if (type == RouteInstructionInstructionType.END_FREE_ZONE && open == RouteInstructionInstructionType.BEGIN_FREE_ZONE) open = null;
      if (type == RouteInstructionInstructionType.END_TRANSIT && open == RouteInstructionInstructionType.BEGIN_TRANSIT) open = null;
    }
    if (open == RouteInstructionInstructionType.BEGIN_FREE_ZONE) return java.util.List.of(RouteInstructionInstructionType.STANDARD, RouteInstructionInstructionType.END_FREE_ZONE);
    if (open == RouteInstructionInstructionType.BEGIN_TRANSIT) return java.util.List.of(RouteInstructionInstructionType.STANDARD, RouteInstructionInstructionType.END_TRANSIT);
    return java.util.List.of(RouteInstructionInstructionType.STANDARD, RouteInstructionInstructionType.BEGIN_FREE_ZONE, RouteInstructionInstructionType.BEGIN_TRANSIT);
  }

  private boolean checkpointAllowed(Long routeId) throws ServiceException {
    return allowedInstructionTypes(routeId).size() == 3;
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
    if (route.getMaximumCheckpointScore() == null) {
      bindingResult.rejectValue("maximumCheckpointScore", "required", "A maximum checkpoint score is required.");
    } else if (route.getMaximumCheckpointScore() < 0) {
      bindingResult.rejectValue("maximumCheckpointScore", "invalid", "Maximum checkpoint score cannot be negative.");
    }
    if (route.getDefaultSpeed() != null && route.getDefaultSpeed() < 0) {
      bindingResult.rejectValue("defaultSpeed", "invalid", "Default speed cannot be negative.");
    }
  }

  private static void validateInstruction(RouteInstructionDTO item, BindingResult bindingResult) {
    validateDistance(item, bindingResult);
    validateOptionalCoordinates(item, bindingResult);
    if (item.getInstructionType() == null) bindingResult.rejectValue("instructionType", "required", "An NRI type is required.");
    if (item.getSpeed() != null && item.getSpeed() < 0) bindingResult.rejectValue("speed", "invalid", "Speed cannot be negative.");
    if (item.getPauseDurationMillis() != null && item.getPauseDurationMillis() < 0) bindingResult.rejectValue("pauseDurationMillis", "invalid", "Pause cannot be negative.");
    if (item.getInstructionType() == RouteInstructionInstructionType.END_TRANSIT && item.getTransitDurationMillis() == null) bindingResult.rejectValue("transitDurationMillis", "required", "Transit duration is required at End Transit.");
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
