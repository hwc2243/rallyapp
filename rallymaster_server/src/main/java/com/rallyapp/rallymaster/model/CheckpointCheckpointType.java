package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum CheckpointCheckpointType {
  PASSAGE_CONTROL("PASSAGE_CONTROL"),
  TIMED_CONTROL("TIMED_CONTROL"),
  START("START"),
  FINISH("FINISH");

  private final String name;

  private CheckpointCheckpointType(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static CheckpointCheckpointType fromValue(String name) {
    return Stream.of(CheckpointCheckpointType.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}
