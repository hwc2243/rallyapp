package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.base.BaseRallyEntry;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RallyEntry;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseRallyEntryEntity extends AbstractBaseEntity
    implements BaseRallyEntry<RallyEntity, RouteEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected String driverFirstName = null;
  
  @Column
  protected String driverLastName = null;
  
  @Column
  protected String navigatorFirstName = null;
  
  @Column
  protected String navigatorLastName = null;
  
  @Column
  protected Long carNumber = null;
  
  @Column
  protected String primaryDeviceId = null;
  
  @Column
  protected String backupDeviceId = null;
  
  @Column
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "rallyId", nullable=true)
  protected RallyEntity rally;

  @ManyToOne
  @JoinColumn(name= "routeId", nullable=true)
  protected RouteEntity route;

  
  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }

  public Object getKey ()
  {
    return this.id;
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
  

  public RallyEntity getRally ()
  {
    return this.rally;
  }
  
  public void setRally (RallyEntity rally)
  {
    this.rally = rally;
  }


  public RouteEntity getRoute ()
  {
    return this.route;
  }
  
  public void setRoute (RouteEntity route)
  {
    this.route = route;
  }



    @Override
	public int hashCode() {
		return Objects.hash(this.getId());
	}
	
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
			
		BaseRallyEntryEntity other = (BaseRallyEntryEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
