package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RallyConfigurationScoringUnit {
  SECONDS("SECONDS"),
  CENTS("CENTS");

  private final String name;

  private RallyConfigurationScoringUnit(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RallyConfigurationScoringUnit fromValue(String name) {
    return Stream.of(RallyConfigurationScoringUnit.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
