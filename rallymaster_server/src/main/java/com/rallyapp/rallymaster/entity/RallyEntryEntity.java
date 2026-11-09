package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRallyEntryEntity;
import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RallyEntry;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RallyEntry")
@Table(name="rally_entry",
       uniqueConstraints = {
               @UniqueConstraint(columnNames = {
                       "rally_id", 
                       "carNumber"
               }),
               @UniqueConstraint(columnNames = {
                       "rally_id", 
                       "primaryDeviceId"
               })
       }
)
public class RallyEntryEntity
    extends BaseRallyEntryEntity
    implements RallyEntry<RallyEntity, RouteEntity>, Serializable
{
	public RallyEntryEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RallyEntryEntity (Builder builder)
    {
        this.driverFirstName = builder.driverFirstName;
        this.driverLastName = builder.driverLastName;
        this.navigatorFirstName = builder.navigatorFirstName;
        this.navigatorLastName = builder.navigatorLastName;
        this.carNumber = builder.carNumber;
        this.primaryDeviceId = builder.primaryDeviceId;
        this.backupDeviceId = builder.backupDeviceId;
        this.organizationId = builder.organizationId;
    }

    public static class Builder {

        private String driverFirstName = null;
        private String driverLastName = null;
        private String navigatorFirstName = null;
        private String navigatorLastName = null;
        private Long carNumber = null;
        private String primaryDeviceId = null;
        private String backupDeviceId = null;
        private Long organizationId = null;

        public Builder driverFirstName(String driverFirstName) {
            this.driverFirstName = driverFirstName;
            return this;
        }

        public Builder driverLastName(String driverLastName) {
            this.driverLastName = driverLastName;
            return this;
        }

        public Builder navigatorFirstName(String navigatorFirstName) {
            this.navigatorFirstName = navigatorFirstName;
            return this;
        }

        public Builder navigatorLastName(String navigatorLastName) {
            this.navigatorLastName = navigatorLastName;
            return this;
        }

        public Builder carNumber(Long carNumber) {
            this.carNumber = carNumber;
            return this;
        }

        public Builder primaryDeviceId(String primaryDeviceId) {
            this.primaryDeviceId = primaryDeviceId;
            return this;
        }

        public Builder backupDeviceId(String backupDeviceId) {
            this.backupDeviceId = backupDeviceId;
            return this;
        }

        public Builder organizationId(Long organizationId) {
            this.organizationId = organizationId;
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RallyEntryEntity build() {
            return new RallyEntryEntity(this);
        }
    }
}
