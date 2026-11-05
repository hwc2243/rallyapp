package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRouteEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.model.Route;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="Route")
@Table(name="route")
public class RouteEntity
    extends BaseRouteEntity
    implements Route<RallyEntity, RouteItemEntity>, Serializable
{
	public RouteEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RouteEntity (Builder builder)
    {
        this.name = builder.name;
        this.description = builder.description;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private String name = null;
        private String description = null;
        private Long organizationId = null;

        public Builder name(String name) {
            this.name = name;
            return this;
        }

        public Builder description(String description) {
            this.description = description;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RouteEntity build() {
            return new RouteEntity(this);
        }
    }
}
