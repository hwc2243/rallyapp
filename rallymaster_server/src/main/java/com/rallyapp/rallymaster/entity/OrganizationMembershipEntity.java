package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseOrganizationMembershipEntity;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.model.OrganizationMembership;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="OrganizationMembership")
@Table(name="organization_membership",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "user_id"
               })
       }
)
public class OrganizationMembershipEntity
    extends BaseOrganizationMembershipEntity<OrganizationMembershipEntity>
    implements OrganizationMembership<UserEntity, OrganizationEntity>, Serializable
{
	public OrganizationMembershipEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private OrganizationMembershipEntity (Builder builder)
    {
        this.role = builder.role;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private OrganizationMembershipRole role = null;
        private Long organizationId = null;

        public Builder role(OrganizationMembershipRole role) {
            this.role = role;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public OrganizationMembershipEntity build() {
            return new OrganizationMembershipEntity(this);
        }
    }
}
