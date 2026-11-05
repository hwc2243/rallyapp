package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.base.BaseRouteItem;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteItem;
import com.rallyapp.rallymaster.model.RouteItemItemType;
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
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseRouteItemEntity<T extends BaseRouteItemEntity<T>> extends AbstractBaseEntity
    implements BaseRouteItem<RouteEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  @Enumerated(EnumType.STRING)
  protected RouteItemItemType itemType = null;
  
  @Column
  protected Long position = null;
  
  @Column
  protected Double latitude = null;
  
  @Column
  protected Double longitude = null;
  
  @Column
  protected Integer heading = null;
  
  @Column
  protected Double distance = null;
  
  @Column
  protected String notes = null;
  
  @Column
  protected Boolean deleted = null;
  
  @Column
  protected Long organizationId = null;
  

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
  

  public RouteItemItemType getItemType ()
  {
    return this.itemType;
  }
  
  public void setItemType (RouteItemItemType itemType)
  {
    this.itemType = itemType;
  }

  public Long getPosition ()
  {
    return this.position;
  }
  
  public void setPosition (Long position)
  {
    this.position = position;
  }
  

  public Double getLatitude ()
  {
    return this.latitude;
  }
  
  public void setLatitude (Double latitude)
  {
    this.latitude = latitude;
  }
  

  public Double getLongitude ()
  {
    return this.longitude;
  }
  
  public void setLongitude (Double longitude)
  {
    this.longitude = longitude;
  }
  

  public Integer getHeading ()
  {
    return this.heading;
  }
  
  public void setHeading (Integer heading)
  {
    this.heading = heading;
  }
  

  public Double getDistance ()
  {
    return this.distance;
  }
  
  public void setDistance (Double distance)
  {
    this.distance = distance;
  }
  

  public String getNotes ()
  {
    return this.notes;
  }
  
  public void setNotes (String notes)
  {
    this.notes = notes;
  }
  

  public Boolean getDeleted ()
  {
    return this.deleted;
  }
  
  public void setDeleted (Boolean deleted)
  {
    this.deleted = deleted;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
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
			
		BaseRouteItemEntity other = (BaseRouteItemEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
