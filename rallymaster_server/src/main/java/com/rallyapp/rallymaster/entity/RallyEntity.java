package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRallyEntity;
import com.rallyapp.rallymaster.model.Rally;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="Rally")
@Table(name="rally")
public class RallyEntity
    extends BaseRallyEntity<RallyEntity>
    implements Rally, Serializable
{
	public RallyEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RallyEntity (Builder builder)
    {
        this.name = builder.name;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private String name = null;
        private Long organizationId = null;

        public Builder name(String name) {
            this.name = name;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RallyEntity build() {
            return new RallyEntity(this);
        }
    }
}
