package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RoutePlanningMode {
  NRI_AND_CHECKPOINTS("NRI_AND_CHECKPOINTS"),
  CHECKPOINTS_ONLY("CHECKPOINTS_ONLY");

  private final String name;

  private RoutePlanningMode(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RoutePlanningMode fromValue(String name) {
    return Stream.of(RoutePlanningMode.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
