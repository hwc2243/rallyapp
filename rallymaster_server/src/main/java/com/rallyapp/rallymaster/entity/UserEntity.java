package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseUserEntity;
import com.rallyapp.rallymaster.model.User;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="User")
@Table(name="user_",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "emailAddress"
               })
       }
)
public class UserEntity
    extends BaseUserEntity<UserEntity>
    implements User<OrganizationMembershipEntity>, Serializable
{
	public UserEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private UserEntity (Builder builder)
    {
        this.emailAddress = builder.emailAddress;
        this.firstName = builder.firstName;
        this.lastName = builder.lastName;
    }

    public static class Builder {

        private String emailAddress = null;
        private String firstName = null;
        private String lastName = null;

        public Builder emailAddress(String emailAddress) {
            this.emailAddress = emailAddress;
            return this;
        }

        public Builder firstName(String firstName) {
            this.firstName = firstName;
            return this;
        }

        public Builder lastName(String lastName) {
            this.lastName = lastName;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public UserEntity build() {
            return new UserEntity(this);
        }
    }
}
