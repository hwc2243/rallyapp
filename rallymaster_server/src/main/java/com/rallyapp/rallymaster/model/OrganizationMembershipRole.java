package com.rallyapp.rallymaster.model;

import java.util.stream.Stream;

public enum OrganizationMembershipRole {
  ADMIN("ADMIN"),
  RALLYMASTER("RALLYMASTER"),
  VIEWER("VIEWER");

  private final String name;

  private OrganizationMembershipRole(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  // A static lookup method to find the enum by its name
  public static OrganizationMembershipRole fromValue(String name) {
    return Stream.of(OrganizationMembershipRole.values())
        .filter(type -> type.getName().equals(name))
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Unknown enum value: " + name));
  }
}