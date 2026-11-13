package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRouteTimingPointEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.RouteTimingPoint;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RouteTimingPoint")
@Table(name="route_timing_point",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "routeTimingPlan_id", 
                       "routeItem_id"
               })
       }
)
public class RouteTimingPointEntity
    extends BaseRouteTimingPointEntity
    implements RouteTimingPoint<RouteTimingPlanEntity, RouteItemEntity>, Serializable
{
	public RouteTimingPointEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RouteTimingPointEntity (Builder builder)
    {
        this.segmentNumber = builder.segmentNumber;
        this.segmentOffsetMillis = builder.segmentOffsetMillis;
        this.carZeroSegmentStartEpochMillis = builder.carZeroSegmentStartEpochMillis;
        this.carZeroIdealArrivalEpochMillis = builder.carZeroIdealArrivalEpochMillis;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private Long segmentNumber = null;
        private Long segmentOffsetMillis = null;
        private Long carZeroSegmentStartEpochMillis = null;
        private Long carZeroIdealArrivalEpochMillis = null;
        private Long organizationId = null;

        public Builder segmentNumber(Long segmentNumber) {
            this.segmentNumber = segmentNumber;
            return this;
        }

        public Builder segmentOffsetMillis(Long segmentOffsetMillis) {
            this.segmentOffsetMillis = segmentOffsetMillis;
            return this;
        }

        public Builder carZeroSegmentStartEpochMillis(Long carZeroSegmentStartEpochMillis) {
            this.carZeroSegmentStartEpochMillis = carZeroSegmentStartEpochMillis;
            return this;
        }

        public Builder carZeroIdealArrivalEpochMillis(Long carZeroIdealArrivalEpochMillis) {
            this.carZeroIdealArrivalEpochMillis = carZeroIdealArrivalEpochMillis;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RouteTimingPointEntity build() {
            return new RouteTimingPointEntity(this);
        }
    }
}
