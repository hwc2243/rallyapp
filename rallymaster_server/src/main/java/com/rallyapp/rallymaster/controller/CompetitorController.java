package com.rallyapp.rallymaster.controller;

import com.rallyapp.rallymaster.api.external.CompetitorEntryResponse;
import com.rallyapp.rallymaster.competition.RallyEntryManagementService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.persistence.CompetitorTelemetryPersistence;
import com.rallyapp.rallymaster.persistence.RallyConfigurationPersistence;
import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.RouteService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
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

/** Authenticated browser management of teams registered for a route. */
@Controller
@RequestMapping("/rally/{rallyId}/routes/{routeId}/competitors")
public class CompetitorController {
  private final RallyService rallyService;
  private final RouteService routeService;
  private final RallyEntryManagementService rallyEntryManagementService;
  private final CompetitorTelemetryPersistence competitorTelemetryPersistence;
  private final RallyConfigurationPersistence rallyConfigurationPersistence;
  private final ObjectMapper objectMapper;

  public CompetitorController(
      RallyService rallyService,
      RouteService routeService,
      RallyEntryManagementService rallyEntryManagementService,
      CompetitorTelemetryPersistence competitorTelemetryPersistence,
      RallyConfigurationPersistence rallyConfigurationPersistence,
      ObjectMapper objectMapper) {
    this.rallyService = rallyService;
    this.routeService = routeService;
    this.rallyEntryManagementService = rallyEntryManagementService;
    this.competitorTelemetryPersistence = competitorTelemetryPersistence;
    this.rallyConfigurationPersistence = rallyConfigurationPersistence;
    this.objectMapper = objectMapper;
  }

  @GetMapping
  public String list(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    List<CompetitorEntryResponse> competitors = rallyEntryManagementService.listForRoute(routeId);
    Long organizationId = currentOrganizationId();
    Set<Long> telemetryEntryIds = competitors.stream()
        .filter(competitor -> competitorTelemetryPersistence
            .existsByOrganizationIdAndRallyEntry_Id(organizationId, competitor.entryId()))
        .map(CompetitorEntryResponse::entryId)
        .collect(Collectors.toSet());
    model.put("competitors", competitors);
    model.put("telemetryEntryIds", telemetryEntryIds);
    return "competitor/list";
  }

  @GetMapping("/{entryId}/telemetry")
  public String telemetry(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long entryId,
      ModelMap model) throws Exception {
    populateRoute(model, rallyId, routeId);
    CompetitorEntryResponse competitor = rallyEntryManagementService.getForRoute(routeId, entryId);
    Long organizationId = currentOrganizationId();
    List<CompetitorTelemetryEntity> telemetry = competitorTelemetryPersistence.findForTelemetryView(
        organizationId, entryId, routeId);
    RallyConfigurationEntity configuration = rallyConfigurationPersistence
        .findFirstByOrganizationIdAndRallyId(organizationId, rallyId);
    ZoneId timeZone = timeZone(configuration);
    model.put("competitor", competitor);
    model.put("timeZone", timeZone.getId());
    model.put("telemetry", telemetry);
    model.put("telemetryJson", objectMapper.writeValueAsString(
        telemetry.stream().map(value -> TelemetryMapValue.from(value, timeZone)).toList()));
    model.put("acquisitionRadiusMeters", configuration == null
        || configuration.getCheckpointAcquisitionRadiusMeters() == null
            ? 150.0
            : configuration.getCheckpointAcquisitionRadiusMeters());
    return "competitor/telemetry";
  }

  @GetMapping("/{entryId}/edit")
  public String edit(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long entryId,
      ModelMap model) throws ServiceException {
    populateRoute(model, rallyId, routeId);
    model.put("entryId", entryId);
    model.put("competitor", CompetitorForm.from(rallyEntryManagementService.getForRoute(routeId, entryId)));
    return "competitor/form";
  }

  @PostMapping("/{entryId}")
  public String update(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long entryId,
      @ModelAttribute("competitor") CompetitorForm competitor,
      BindingResult bindingResult,
      ModelMap model) throws ServiceException {
    validate(competitor, bindingResult);
    if (bindingResult.hasErrors()) {
      populateRoute(model, rallyId, routeId);
      model.put("entryId", entryId);
      return "competitor/form";
    }
    try {
      rallyEntryManagementService.updateForRoute(
          routeId,
          entryId,
          competitor.getCarNumber(),
          competitor.getDriverFirstName(),
          competitor.getDriverLastName(),
          competitor.getNavigatorFirstName(),
          competitor.getNavigatorLastName());
    } catch (IllegalArgumentException ex) {
      bindingResult.rejectValue("carNumber", "invalid", ex.getMessage());
      populateRoute(model, rallyId, routeId);
      model.put("entryId", entryId);
      return "competitor/form";
    }
    return redirectToList(rallyId, routeId);
  }

  @PostMapping("/{entryId}/delete")
  public String delete(
      @PathVariable Long rallyId,
      @PathVariable Long routeId,
      @PathVariable Long entryId) throws ServiceException {
    route(rallyId, routeId);
    rallyEntryManagementService.deleteForRoute(routeId, entryId);
    return redirectToList(rallyId, routeId);
  }

  private void populateRoute(ModelMap model, Long rallyId, Long routeId) throws ServiceException {
    model.put("rally", rally(rallyId));
    model.put("route", route(rallyId, routeId));
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

  private static void validate(CompetitorForm competitor, BindingResult bindingResult) {
    if (competitor.getCarNumber() == null || competitor.getCarNumber() < 1) {
      bindingResult.rejectValue("carNumber", "invalid", "A positive car number is required.");
    }
    required(competitor.getDriverFirstName(), "driverFirstName", "Driver first name", bindingResult);
    required(competitor.getDriverLastName(), "driverLastName", "Driver last name", bindingResult);
    required(competitor.getNavigatorFirstName(), "navigatorFirstName", "Navigator first name", bindingResult);
    required(competitor.getNavigatorLastName(), "navigatorLastName", "Navigator last name", bindingResult);
  }

  private static void required(String value, String field, String label, BindingResult bindingResult) {
    if (value == null || value.isBlank()) bindingResult.rejectValue(field, "required", label + " is required.");
  }

  private static String redirectToList(Long rallyId, Long routeId) {
    return "redirect:/rally/" + rallyId + "/routes/" + routeId + "/competitors";
  }

  private static ZoneId timeZone(RallyConfigurationEntity configuration) {
    if (configuration == null || configuration.getTimeZone() == null
        || configuration.getTimeZone().isBlank()) return ZoneOffset.UTC;
    try {
      return ZoneId.of(configuration.getTimeZone());
    } catch (Exception ignored) {
      return ZoneOffset.UTC;
    }
  }

  private static Long currentOrganizationId() {
    if (SessionContext.getCurrentOrganization() == null
        || SessionContext.getCurrentOrganization().getId() == null) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Select an organization first.");
    }
    return SessionContext.getCurrentOrganization().getId();
  }

  private static ResponseStatusException notFound(String type) {
    return new ResponseStatusException(HttpStatus.NOT_FOUND, type + " was not found.");
  }

  /** Mutable form containing only the team details a rallymaster may change. */
  public static class CompetitorForm {
    private Long carNumber;
    private String driverFirstName;
    private String driverLastName;
    private String navigatorFirstName;
    private String navigatorLastName;

    static CompetitorForm from(CompetitorEntryResponse entry) {
      CompetitorForm form = new CompetitorForm();
      form.carNumber = entry.carNumber();
      form.driverFirstName = entry.driverFirstName();
      form.driverLastName = entry.driverLastName();
      form.navigatorFirstName = entry.navigatorFirstName();
      form.navigatorLastName = entry.navigatorLastName();
      return form;
    }

    public Long getCarNumber() { return carNumber; }
    public void setCarNumber(Long carNumber) { this.carNumber = carNumber; }
    public String getDriverFirstName() { return driverFirstName; }
    public void setDriverFirstName(String driverFirstName) { this.driverFirstName = driverFirstName; }
    public String getDriverLastName() { return driverLastName; }
    public void setDriverLastName(String driverLastName) { this.driverLastName = driverLastName; }
    public String getNavigatorFirstName() { return navigatorFirstName; }
    public void setNavigatorFirstName(String navigatorFirstName) { this.navigatorFirstName = navigatorFirstName; }
    public String getNavigatorLastName() { return navigatorLastName; }
    public void setNavigatorLastName(String navigatorLastName) { this.navigatorLastName = navigatorLastName; }
  }

  private record TelemetryMapValue(
      Long checkpointId,
      Long checkpointNumber,
      String checkpointType,
      String checkpointName,
      Double checkpointLatitude,
      Double checkpointLongitude,
      Integer checkpointHeading,
      String occurredAt,
      Double interceptLatitude,
      Double interceptLongitude,
      Double interceptHeading,
      Double interceptSpeed,
      Double interceptAccuracy,
      Double closestDistanceMeters,
      List<TelemetrySampleValue> samples) {
    static TelemetryMapValue from(CompetitorTelemetryEntity telemetry, ZoneId timeZone) {
      var checkpoint = telemetry.getCheckpoint();
      return new TelemetryMapValue(
          checkpoint.getId(), checkpoint.getCheckpointNumber(),
          checkpoint.getCheckpointType() == null ? null : checkpoint.getCheckpointType().name(),
          checkpoint.getName(), checkpoint.getLatitude(), checkpoint.getLongitude(), checkpoint.getHeading(),
          format(telemetry.getOccurredAt(), timeZone), telemetry.getInterceptLatitude(),
          telemetry.getInterceptLongitude(), telemetry.getInterceptHeading(), telemetry.getInterceptSpeed(),
          telemetry.getInterceptAccuracy(), telemetry.getClosestDistanceMeters(),
          telemetry.getData().stream()
              .sorted(Comparator.comparing(CompetitorTelemetryDataEntity::getCapturedAt))
              .map(sample -> TelemetrySampleValue.from(sample, timeZone)).toList());
    }
  }

  private record TelemetrySampleValue(
      Double latitude, Double longitude, Double heading, Double speed, Double accuracy, String capturedAt) {
    static TelemetrySampleValue from(CompetitorTelemetryDataEntity sample, ZoneId timeZone) {
      return new TelemetrySampleValue(sample.getLatitude(), sample.getLongitude(), sample.getHeading(),
          sample.getSpeed(), sample.getAccuracy(), format(sample.getCapturedAt(), timeZone));
    }
  }

  private static String format(LocalDateTime value, ZoneId timeZone) {
    if (value == null) return null;
    return value.atZone(ZoneOffset.UTC).withZoneSameInstant(timeZone)
        .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
  }
}
