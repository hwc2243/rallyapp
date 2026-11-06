package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum RouteItemItemType {
  NRI("NRI"),
  CHECKPOINT("CHECKPOINT");

  private final String name;

  private RouteItemItemType(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static RouteItemItemType fromValue(String name) {
    return Stream.of(RouteItemItemType.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
