package com.rallyapp.rallymaster.api.external;

/** The shared competitor password is accepted only while publishing. */
public record PublishRouteRequest(String eventPassword) {
}
