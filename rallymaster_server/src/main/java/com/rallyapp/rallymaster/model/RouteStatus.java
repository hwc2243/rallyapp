package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RouteStatus {
  PLAN("PLAN"),
  ACTIVE("ACTIVE"),
  COMPLETED("COMPLETED");

  private final String name;

  private RouteStatus(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RouteStatus fromValue(String name) {
    return Stream.of(RouteStatus.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
