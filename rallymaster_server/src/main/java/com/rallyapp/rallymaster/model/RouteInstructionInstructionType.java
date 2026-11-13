package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RouteInstructionInstructionType {
  STANDARD("STANDARD"),
  BEGIN_FREE_ZONE("BEGIN_FREE_ZONE"),
  END_FREE_ZONE("END_FREE_ZONE"),
  BEGIN_TRANSIT("BEGIN_TRANSIT"),
  END_TRANSIT("END_TRANSIT");

  private final String name;

  private RouteInstructionInstructionType(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RouteInstructionInstructionType fromValue(String name) {
    return Stream.of(RouteInstructionInstructionType.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
