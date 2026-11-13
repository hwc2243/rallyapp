package com.rallyapp.rallymaster.controller;

import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.service.RallyConfigurationService;
import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;

/** Organizer-facing rally details and rally-wide defaults. */
@Controller
@RequestMapping("/rally")
public class RallyController {
  @Autowired protected RallyService rallyService;
  @Autowired protected RallyConfigurationService rallyConfigurationService;
  @Autowired protected RallyConfigurationPersistence rallyConfigurationPersistence;
  @Autowired protected RouteService routeService;

  @GetMapping({"", "/", "/list", "/list.html"})
  public String list(ModelMap model) throws ServiceException {
    model.put("rallys", rallyService.findAll());
    return "rally/list";
  }

  @GetMapping("/new")
  public String newRally(ModelMap model) {
    model.put("rally", new RallyDTO());
    populateSettings(model, null);
    return "rally/form";
  }

  @PostMapping
  public String create(@ModelAttribute("rally") RallyDTO rally, BindingResult errors,
      @RequestParam String distanceUnit, @RequestParam String scoringUnit,
      @RequestParam String carStartInterval, @RequestParam(required = false) Double defaultSpeed,
      @RequestParam(required = false) String defaultRestartInterval,
      @RequestParam(required = false) String defaultPauseDuration, ModelMap model) throws ServiceException {
    validateRally(rally, errors);
    if (SessionContext.getCurrentOrganization() == null) return "redirect:/home";
    if (errors.hasErrors()) { populateSettings(model, null); return "rally/form"; }
    rally.setName(rally.getName().trim());
    rally.setOrganizationId(SessionContext.getCurrentOrganization().getId());
    RallyDTO created = rallyService.create(rally);
    RallyConfigurationDTO settings = settings(created, distanceUnit, scoringUnit, carStartInterval,
        defaultSpeed, defaultRestartInterval, defaultPauseDuration, errors);
    if (errors.hasErrors()) return "redirect:/rally/" + created.getId() + "/edit";
    rallyConfigurationService.create(settings);
    return "redirect:/rally/list";
  }

  @GetMapping("/{rallyId}/edit")
  public String edit(@PathVariable Long rallyId, ModelMap model) throws ServiceException {
    RallyDTO rally = getRally(rallyId);
    ensureEditable(rallyId);
    model.put("rally", rally); model.put("editing", true); populateSettings(model, rallyId);
    return "rally/form";
  }

  @PostMapping("/{rallyId}")
  public String update(@PathVariable Long rallyId, @ModelAttribute("rally") RallyDTO rally,
      BindingResult errors, @RequestParam String distanceUnit, @RequestParam String scoringUnit,
      @RequestParam String carStartInterval, @RequestParam(required = false) Double defaultSpeed,
      @RequestParam(required = false) String defaultRestartInterval,
      @RequestParam(required = false) String defaultPauseDuration, ModelMap model) throws ServiceException {
    RallyDTO existing = getRally(rallyId); ensureEditable(rallyId);
    rally.setId(existing.getId()); rally.setOrganizationId(existing.getOrganizationId()); rally.setUserId(existing.getUserId());
    validateRally(rally, errors);
    RallyConfigurationDTO settings = settings(rally, distanceUnit, scoringUnit, carStartInterval,
        defaultSpeed, defaultRestartInterval, defaultPauseDuration, errors);
    if (errors.hasErrors()) { model.put("editing", true); populateSettings(model, rallyId); return "rally/form"; }
    rally.setName(rally.getName().trim()); rallyService.update(rally);
    RallyConfigurationDTO prior = findSettings(rallyId);
    if (prior != null) settings.setId(prior.getId());
    if (settings.getId() == null) rallyConfigurationService.create(settings); else rallyConfigurationService.update(settings);
    return "redirect:/rally/list";
  }

  @PostMapping("/{rallyId}/delete")
  public String delete(@PathVariable Long rallyId) throws ServiceException {
    try {
      rallyService.delete(rallyId);
      return "redirect:/rally/list";
    } catch (ServiceException ex) {
      if (ex.getMessage() != null && ex.getMessage().contains("active or completed")) {
        throw new ResponseStatusException(HttpStatus.CONFLICT, ex.getMessage());
      }
      throw ex;
    }
  }

  private RallyDTO getRally(Long id) throws ServiceException {
    RallyDTO rally = rallyService.get(id);
    if (rally == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    return rally;
  }

  private void ensureEditable(Long rallyId) throws ServiceException {
    if (routeService.findByRallyId(rallyId).stream().anyMatch(route -> route.getStatus() == RouteStatus.ACTIVE)) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Rally details cannot change after a route is active.");
    }
  }

  private static void validateRally(RallyDTO rally, BindingResult errors) {
    if (rally.getName() == null || rally.getName().isBlank()) errors.rejectValue("name", "required", "A rally name is required.");
    if (rally.getDate() == null) errors.rejectValue("date", "required", "A rally date is required.");
  }

  private RallyConfigurationDTO settings(RallyDTO rally, String distanceUnit, String scoringUnit,
      String carStartInterval, Double defaultSpeed, String defaultRestartInterval, String defaultPauseDuration,
      BindingResult errors) {
    RallyConfigurationDTO result = new RallyConfigurationDTO();
    result.setRallyId(rally.getId()); result.setOrganizationId(rally.getOrganizationId());
    try {
      result.setDistanceUnit(RallyConfigurationDistanceUnit.valueOf(distanceUnit));
      result.setScoringUnit(RallyConfigurationScoringUnit.valueOf(scoringUnit));
      result.setCarStartIntervalMillis(parseDuration(carStartInterval, true));
      result.setDefaultSpeed(defaultSpeed);
      result.setDefaultRestartIntervalMillis(parseDuration(defaultRestartInterval, false));
      result.setDefaultPauseDurationMillis(parseDuration(defaultPauseDuration, false));
    } catch (RuntimeException ex) { errors.reject("settings", "Enter a valid configuration; durations use mm:ss."); }
    return result;
  }

  private static Long parseDuration(String value, boolean required) {
    if (value == null || value.isBlank()) { if (required) throw new IllegalArgumentException(); return null; }
    String[] parts = value.trim().split(":"); if (parts.length != 2) throw new IllegalArgumentException();
    long minutes = Long.parseLong(parts[0]); long seconds = Long.parseLong(parts[1]);
    if (minutes < 0 || seconds < 0 || seconds >= 60) throw new IllegalArgumentException();
    return (minutes * 60 + seconds) * 1000;
  }

  private void populateSettings(ModelMap model, Long rallyId) {
    RallyConfigurationDTO config = rallyId == null ? null : findSettings(rallyId);
    model.put("distanceUnit", config == null || config.getDistanceUnit() == null ? "MILES" : config.getDistanceUnit().name());
    model.put("scoringUnit", config == null || config.getScoringUnit() == null ? "SECONDS" : config.getScoringUnit().name());
    model.put("carStartInterval", duration(config == null ? 60_000L : config.getCarStartIntervalMillis()));
    model.put("defaultSpeed", config == null ? null : config.getDefaultSpeed());
    model.put("defaultRestartInterval", duration(config == null ? null : config.getDefaultRestartIntervalMillis()));
    model.put("defaultPauseDuration", duration(config == null ? null : config.getDefaultPauseDurationMillis()));
  }

  private RallyConfigurationDTO findSettings(Long rallyId) {
    var entity = rallyConfigurationPersistence.findFirstByRally_Id(rallyId);
    if (entity == null) return null;
    RallyConfigurationDTO dto = new RallyConfigurationDTO();
    dto.setId(entity.getId()); dto.setRallyId(rallyId); dto.setOrganizationId(entity.getOrganizationId());
    dto.setDistanceUnit(entity.getDistanceUnit()); dto.setScoringUnit(entity.getScoringUnit());
    dto.setCarStartIntervalMillis(entity.getCarStartIntervalMillis()); dto.setDefaultSpeed(entity.getDefaultSpeed());
    dto.setDefaultRestartIntervalMillis(entity.getDefaultRestartIntervalMillis()); dto.setDefaultPauseDurationMillis(entity.getDefaultPauseDurationMillis());
    return dto;
  }

  private static String duration(Long millis) {
    if (millis == null) return ""; long seconds = millis / 1000; return "%d:%02d".formatted(seconds / 60, seconds % 60);
  }
}
