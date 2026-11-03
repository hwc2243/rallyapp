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
public abstract class RouteItemEntity<T extends BaseRouteItemEntity<T>>
    extends BaseRouteItemEntity<T>
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
        this.revision = builder.revision;
        this.deleted = builder.deleted;
        this.organizationId = builder.organizationId;
    }

    public abstract static class Builder<B extends Builder<B>> {

        protected RouteItemItemType itemType = null;
        protected Long position = null;
        protected Long revision = null;
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

        public B revision(Long revision) {
            this.revision = revision;
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
