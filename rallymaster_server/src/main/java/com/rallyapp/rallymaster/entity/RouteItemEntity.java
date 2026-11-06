package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteItem;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RouteItem")
@Table(name="route_item")
@Inheritance(strategy = InheritanceType.JOINED)
public abstract class RouteItemEntity
    extends BaseRouteItemEntity
    implements RouteItem<RouteEntity>, Serializable
{
	public RouteItemEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RouteItemEntity (Builder builder)
    {
        this.itemType = builder.itemType;
        this.position = builder.position;
        this.latitude = builder.latitude;
        this.longitude = builder.longitude;
        this.heading = builder.heading;
        this.distance = builder.distance;
        this.notes = builder.notes;
        this.deleted = builder.deleted;
        this.organizationId = builder.organizationId;
    }

    public abstract static class Builder<B extends Builder<B>> {

        protected RouteItemItemType itemType = null;
        protected Long position = null;
        protected Double latitude = null;
        protected Double longitude = null;
        protected Integer heading = null;
        protected Double distance = null;
        protected String notes = null;
        protected Boolean deleted = null;
        protected Long organizationId = null;

        public B itemType(RouteItemItemType itemType) {
            this.itemType = itemType;
            return self();
        }

        public B position(Long position) {
            this.position = position;
            return self();
        }

        public B latitude(Double latitude) {
            this.latitude = latitude;
            return self();
        }

        public B longitude(Double longitude) {
            this.longitude = longitude;
            return self();
        }

        public B heading(Integer heading) {
            this.heading = heading;
            return self();
        }

        public B distance(Double distance) {
            this.distance = distance;
            return self();
        }

        public B notes(String notes) {
            this.notes = notes;
            return self();
        }

        public B deleted(Boolean deleted) {
            this.deleted = deleted;
            return self();
        }

        public B organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return self();
        }

        protected abstract B self();
    }
}
