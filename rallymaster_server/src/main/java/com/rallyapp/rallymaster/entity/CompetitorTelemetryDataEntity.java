package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseCompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.model.CompetitorTelemetryData;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity(name="CompetitorTelemetryData")
@Table(name="competitor_telemetry_data")
public class CompetitorTelemetryDataEntity
    extends BaseCompetitorTelemetryDataEntity
    implements CompetitorTelemetryData<CompetitorTelemetryEntity>, Serializable
{
	public CompetitorTelemetryDataEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private CompetitorTelemetryDataEntity (Builder builder)
    {
        this.capturedAt = builder.capturedAt;
        this.latitude = builder.latitude;
        this.longitude = builder.longitude;
        this.heading = builder.heading;
        this.speed = builder.speed;
        this.accuracy = builder.accuracy;
        this.distanceToCheckpointMeters = builder.distanceToCheckpointMeters;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private LocalDateTime capturedAt = null;
        private Double latitude = null;
        private Double longitude = null;
        private Double heading = null;
        private Double speed = null;
        private Double accuracy = null;
        private Double distanceToCheckpointMeters = null;
        private Long organizationId = null;

        public Builder capturedAt(LocalDateTime capturedAt) {
            this.capturedAt = capturedAt;
            return this;
        }

        public Builder latitude(Double latitude) {
            this.latitude = latitude;
            return this;
        }

        public Builder longitude(Double longitude) {
            this.longitude = longitude;
            return this;
        }

        public Builder heading(Double heading) {
            this.heading = heading;
            return this;
        }

        public Builder speed(Double speed) {
            this.speed = speed;
            return this;
        }

        public Builder accuracy(Double accuracy) {
            this.accuracy = accuracy;
            return this;
        }

        public Builder distanceToCheckpointMeters(Double distanceToCheckpointMeters) {
            this.distanceToCheckpointMeters = distanceToCheckpointMeters;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public CompetitorTelemetryDataEntity build() {
            return new CompetitorTelemetryDataEntity(this);
        }
    }
}
