package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RouteTimingPlanScoringUnit {
  SECONDS("SECONDS"),
  CENTS("CENTS");

  private final String name;

  private RouteTimingPlanScoringUnit(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RouteTimingPlanScoringUnit fromValue(String name) {
    return Stream.of(RouteTimingPlanScoringUnit.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
