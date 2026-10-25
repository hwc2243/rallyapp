package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseOrganizationEntity;
import com.rallyapp.rallymaster.model.Organization;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="Organization")
@Table(name="organization",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "name"
               })
       }
)
public class OrganizationEntity
    extends BaseOrganizationEntity<OrganizationEntity>
    implements Organization<OrganizationMembershipEntity>, Serializable
{
	public OrganizationEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private OrganizationEntity (Builder builder)
    {
        this.name = builder.name;
    }

    public static class Builder {

        private String name = null;

        public Builder name(String name) {
            this.name = name;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public OrganizationEntity build() {
            return new OrganizationEntity(this);
        }
    }
}
