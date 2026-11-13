package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RallyConfigurationDistanceUnit {
  MILES("MILES"),
  KILOMETERS("KILOMETERS");

  private final String name;

  private RallyConfigurationDistanceUnit(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RallyConfigurationDistanceUnit fromValue(String name) {
    return Stream.of(RallyConfigurationDistanceUnit.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
