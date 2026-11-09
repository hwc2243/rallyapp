package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.model.base.BaseRallyEntry;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRallyEntryDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected String driverFirstName = null;
  
  protected String driverLastName = null;
  
  protected String navigatorFirstName = null;
  
  protected String navigatorLastName = null;
  
  protected Long carNumber = null;
  
  protected String primaryDeviceId = null;
  
  protected String backupDeviceId = null;
  
  protected Long organizationId = null;
  
  protected Long rallyId;

  protected Long routeId;


  protected BaseRallyEntryDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRallyEntryDTO (Builder builder)
  {
    this.id = builder.id;
    this.driverFirstName = builder.driverFirstName;
    this.driverLastName = builder.driverLastName;
    this.navigatorFirstName = builder.navigatorFirstName;
    this.navigatorLastName = builder.navigatorLastName;
    this.carNumber = builder.carNumber;
    this.primaryDeviceId = builder.primaryDeviceId;
    this.backupDeviceId = builder.backupDeviceId;
    this.organizationId = builder.organizationId;
    this.rallyId = builder.rallyId;
    this.routeId = builder.routeId;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public String getDriverFirstName ()
  {
    return this.driverFirstName;
  }
  
  public void setDriverFirstName (String driverFirstName)
  {
    this.driverFirstName = driverFirstName;
  }
  

  public String getDriverLastName ()
  {
    return this.driverLastName;
  }
  
  public void setDriverLastName (String driverLastName)
  {
    this.driverLastName = driverLastName;
  }
  

  public String getNavigatorFirstName ()
  {
    return this.navigatorFirstName;
  }
  
  public void setNavigatorFirstName (String navigatorFirstName)
  {
    this.navigatorFirstName = navigatorFirstName;
  }
  

  public String getNavigatorLastName ()
  {
    return this.navigatorLastName;
  }
  
  public void setNavigatorLastName (String navigatorLastName)
  {
    this.navigatorLastName = navigatorLastName;
  }
  

  public Long getCarNumber ()
  {
    return this.carNumber;
  }
  
  public void setCarNumber (Long carNumber)
  {
    this.carNumber = carNumber;
  }
  

  public String getPrimaryDeviceId ()
  {
    return this.primaryDeviceId;
  }
  
  public void setPrimaryDeviceId (String primaryDeviceId)
  {
    this.primaryDeviceId = primaryDeviceId;
  }
  

  public String getBackupDeviceId ()
  {
    return this.backupDeviceId;
  }
  
  public void setBackupDeviceId (String backupDeviceId)
  {
    this.backupDeviceId = backupDeviceId;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public Long getRallyId ()
  {
    return this.rallyId;
  }

  public void setRallyId (Long rallyId)
  {
    this.rallyId = rallyId;
  }

  public Long getRouteId ()
  {
    return this.routeId;
  }

  public void setRouteId (Long routeId)
  {
    this.routeId = routeId;
  }


    @Override
	public int hashCode() {
		return Objects.hash(id);
	}
	
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
			
		BaseRallyEntryDTO other = (BaseRallyEntryDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String driverFirstName = null;
  
  private String driverLastName = null;
  
  private String navigatorFirstName = null;
  
  private String navigatorLastName = null;
  
  private Long carNumber = null;
  
  private String primaryDeviceId = null;
  
  private String backupDeviceId = null;
  
  private Long organizationId = null;
  

    private Long rallyId = null;
    private Long routeId = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
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

    public Builder rallyId (Long rallyId) {
      this.rallyId = rallyId;
      return this;
    }
    public Builder routeId (Long routeId) {
      this.routeId = routeId;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RallyEntryDTO build();
  }
}
