package com.rallyapp.rallymaster.dto;

import java.util.ArrayList;
import java.util.List;

/** Complete editable route-plan payload used by the mobile planning client. */
public class RoutePlanDTO {
  private List<RouteInstructionDTO> routeInstructions = new ArrayList<>();
  private List<CheckpointDTO> checkpoints = new ArrayList<>();

  public List<RouteInstructionDTO> getRouteInstructions() {
    return routeInstructions;
  }

  public void setRouteInstructions(List<RouteInstructionDTO> routeInstructions) {
    this.routeInstructions = routeInstructions == null ? new ArrayList<>() : routeInstructions;
  }

  public List<CheckpointDTO> getCheckpoints() {
    return checkpoints;
  }

  public void setCheckpoints(List<CheckpointDTO> checkpoints) {
    this.checkpoints = checkpoints == null ? new ArrayList<>() : checkpoints;
  }
}
