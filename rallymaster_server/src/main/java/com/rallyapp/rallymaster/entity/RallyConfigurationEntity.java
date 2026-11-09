package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRallyConfigurationEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.model.RallyConfiguration;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RallyConfiguration")
@Table(name="rally_configuration",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "rally_id"
               })
       }
)
public class RallyConfigurationEntity
    extends BaseRallyConfigurationEntity
    implements RallyConfiguration<RallyEntity>, Serializable
{
	public RallyConfigurationEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RallyConfigurationEntity (Builder builder)
    {
        this.scoringUnit = builder.scoringUnit;
        this.eventPasswordHash = builder.eventPasswordHash;
        this.timeZone = builder.timeZone;
        this.checkpointAcquisitionRadiusMeters = builder.checkpointAcquisitionRadiusMeters;
        this.maximumCheckpointScore = builder.maximumCheckpointScore;
        this.startIntervalSeconds = builder.startIntervalSeconds;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private RallyConfigurationScoringUnit scoringUnit = null;
        private String eventPasswordHash = null;
        private String timeZone = null;
        private Double checkpointAcquisitionRadiusMeters = null;
        private Long maximumCheckpointScore = null;
        private Long startIntervalSeconds = null;
        private Long organizationId = null;

        public Builder scoringUnit(RallyConfigurationScoringUnit scoringUnit) {
            this.scoringUnit = scoringUnit;
            return this;
        }

        public Builder eventPasswordHash(String eventPasswordHash) {
            this.eventPasswordHash = eventPasswordHash;
            return this;
        }

        public Builder timeZone(String timeZone) {
            this.timeZone = timeZone;
            return this;
        }

        public Builder checkpointAcquisitionRadiusMeters(Double checkpointAcquisitionRadiusMeters) {
            this.checkpointAcquisitionRadiusMeters = checkpointAcquisitionRadiusMeters;
            return this;
        }

        public Builder maximumCheckpointScore(Long maximumCheckpointScore) {
            this.maximumCheckpointScore = maximumCheckpointScore;
            return this;
        }

        public Builder startIntervalSeconds(Long startIntervalSeconds) {
            this.startIntervalSeconds = startIntervalSeconds;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RallyConfigurationEntity build() {
            return new RallyConfigurationEntity(this);
        }
    }
}
