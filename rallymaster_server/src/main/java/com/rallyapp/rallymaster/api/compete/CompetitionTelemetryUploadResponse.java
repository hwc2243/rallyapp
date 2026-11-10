package com.rallyapp.rallymaster.api.compete;

/** Result of an idempotent telemetry upload. */
public record CompetitionTelemetryUploadResponse(int accepted, int alreadyUploaded) {}
