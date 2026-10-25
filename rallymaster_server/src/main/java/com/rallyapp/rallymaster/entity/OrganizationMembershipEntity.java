package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseOrganizationMembershipEntity;
import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.model.OrganizationMembership;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="OrganizationMembership")
@Table(name="organization_membership")
public class OrganizationMembershipEntity
    extends BaseOrganizationMembershipEntity<OrganizationMembershipEntity>
    implements OrganizationMembership, Serializable
{
	/**
	 * Read-only association for the inverse UserEntity.memberships mapping.
	 * The generated userId field remains the authoritative, writable value.
	 */
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "userId", insertable = false, updatable = false)
	private UserEntity user;

	/**
	 * Read-only association for the inverse OrganizationEntity.memberships mapping.
	 * The generated organizationId field remains the authoritative tenant key.
	 */
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "organizationId", insertable = false, updatable = false)
	private OrganizationEntity organization;

	public OrganizationMembershipEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private OrganizationMembershipEntity (Builder builder)
    {
        this.role = builder.role;
    }

    public static class Builder {

        private OrganizationMembershipRole role = null;

        public Builder role(OrganizationMembershipRole role) {
            this.role = role;
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
