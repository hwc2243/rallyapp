package com.rallyapp.rallymaster.api.external;

/** Safe publish metadata for an authenticated RallyMaster; no configuration values are exposed. */
public record RallyPublishStatusResponse(boolean eventPasswordConfigured) {
}
