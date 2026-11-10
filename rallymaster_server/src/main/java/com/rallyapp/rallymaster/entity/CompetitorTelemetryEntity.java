package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseCompetitorTelemetryEntity;
import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.CompetitorTelemetry;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity(name="CompetitorTelemetry")
@Table(name="competitor_telemetry",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "rallyEntry_id", 
                       "checkpoint_id", 
                       "occurredAt"
               })
       }
)
public class CompetitorTelemetryEntity
    extends BaseCompetitorTelemetryEntity
    implements CompetitorTelemetry<RallyEntryEntity, RouteEntity, CheckpointEntity, CompetitorTelemetryDataEntity>, Serializable
{
	public CompetitorTelemetryEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private CompetitorTelemetryEntity (Builder builder)
    {
        this.occurredAt = builder.occurredAt;
        this.interceptLatitude = builder.interceptLatitude;
        this.interceptLongitude = builder.interceptLongitude;
        this.interceptHeading = builder.interceptHeading;
        this.interceptSpeed = builder.interceptSpeed;
        this.interceptAccuracy = builder.interceptAccuracy;
        this.closestDistanceMeters = builder.closestDistanceMeters;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private LocalDateTime occurredAt = null;
        private Double interceptLatitude = null;
        private Double interceptLongitude = null;
        private Double interceptHeading = null;
        private Double interceptSpeed = null;
        private Double interceptAccuracy = null;
        private Double closestDistanceMeters = null;
        private Long organizationId = null;

        public Builder occurredAt(LocalDateTime occurredAt) {
            this.occurredAt = occurredAt;
            return this;
        }

        public Builder interceptLatitude(Double interceptLatitude) {
            this.interceptLatitude = interceptLatitude;
            return this;
        }

        public Builder interceptLongitude(Double interceptLongitude) {
            this.interceptLongitude = interceptLongitude;
            return this;
        }

        public Builder interceptHeading(Double interceptHeading) {
            this.interceptHeading = interceptHeading;
            return this;
        }

        public Builder interceptSpeed(Double interceptSpeed) {
            this.interceptSpeed = interceptSpeed;
            return this;
        }

        public Builder interceptAccuracy(Double interceptAccuracy) {
            this.interceptAccuracy = interceptAccuracy;
            return this;
        }

        public Builder closestDistanceMeters(Double closestDistanceMeters) {
            this.closestDistanceMeters = closestDistanceMeters;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public CompetitorTelemetryEntity build() {
            return new CompetitorTelemetryEntity(this);
        }
    }
}
