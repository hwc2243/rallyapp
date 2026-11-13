package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRouteTimingPlanEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.model.RouteTimingPlan;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RouteTimingPlan")
@Table(name="route_timing_plan",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "route_id"
               })
       }
)
public class RouteTimingPlanEntity
    extends BaseRouteTimingPlanEntity
    implements RouteTimingPlan<RouteEntity, RouteTimingPointEntity>, Serializable
{
	public RouteTimingPlanEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RouteTimingPlanEntity (Builder builder)
    {
        this.version = builder.version;
        this.carZeroStartEpochMillis = builder.carZeroStartEpochMillis;
        this.distanceUnit = builder.distanceUnit;
        this.scoringUnit = builder.scoringUnit;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private Long version = null;
        private Long carZeroStartEpochMillis = null;
        private RouteTimingPlanDistanceUnit distanceUnit = null;
        private RouteTimingPlanScoringUnit scoringUnit = null;
        private Long organizationId = null;

        public Builder version(Long version) {
            this.version = version;
            return this;
        }

        public Builder carZeroStartEpochMillis(Long carZeroStartEpochMillis) {
            this.carZeroStartEpochMillis = carZeroStartEpochMillis;
            return this;
        }

        public Builder distanceUnit(RouteTimingPlanDistanceUnit distanceUnit) {
            this.distanceUnit = distanceUnit;
            return this;
        }

        public Builder scoringUnit(RouteTimingPlanScoringUnit scoringUnit) {
            this.scoringUnit = scoringUnit;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RouteTimingPlanEntity build() {
            return new RouteTimingPlanEntity(this);
        }
    }
}
