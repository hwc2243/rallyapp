package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RouteTimingPlanDistanceUnit {
  MILES("MILES"),
  KILOMETERS("KILOMETERS");

  private final String name;

  private RouteTimingPlanDistanceUnit(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RouteTimingPlanDistanceUnit fromValue(String name) {
    return Stream.of(RouteTimingPlanDistanceUnit.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
