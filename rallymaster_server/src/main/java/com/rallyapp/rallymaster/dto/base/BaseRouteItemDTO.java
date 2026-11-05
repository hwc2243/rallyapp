package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.model.base.BaseRouteItem;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteItemDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected RouteItemItemType itemType = null;
  
  protected Long position = null;
  
  protected Double latitude = null;
  
  protected Double longitude = null;
  
  protected Integer heading = null;
  
  protected Double distance = null;
  
  protected String notes = null;
  
  protected Boolean deleted = null;
  
  protected Long organizationId = null;
  
  protected Long routeId;


  protected BaseRouteItemDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteItemDTO (Builder builder)
  {
    this.id = builder.id;
    this.itemType = builder.itemType;
    this.position = builder.position;
    this.latitude = builder.latitude;
    this.longitude = builder.longitude;
    this.heading = builder.heading;
    this.distance = builder.distance;
    this.notes = builder.notes;
    this.deleted = builder.deleted;
    this.organizationId = builder.organizationId;
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
			
		BaseRouteItemDTO other = (BaseRouteItemDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private RouteItemItemType itemType = null;
  
  private Long position = null;
  
  private Double latitude = null;
  
  private Double longitude = null;
  
  private Integer heading = null;
  
  private Double distance = null;
  
  private String notes = null;
  
  private Boolean deleted = null;
  
  private Long organizationId = null;
  

    private Long routeId = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder itemType(RouteItemItemType itemType) {
      this.itemType = itemType;
      return this;
    }

    public Builder position(Long position) {
      this.position = position;
      return this;
    }

    public Builder latitude(Double latitude) {
      this.latitude = latitude;
      return this;
    }

    public Builder longitude(Double longitude) {
      this.longitude = longitude;
      return this;
    }

    public Builder heading(Integer heading) {
      this.heading = heading;
      return this;
    }

    public Builder distance(Double distance) {
      this.distance = distance;
      return this;
    }

    public Builder notes(String notes) {
      this.notes = notes;
      return this;
    }

    public Builder deleted(Boolean deleted) {
      this.deleted = deleted;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    public Builder routeId (Long routeId) {
      this.routeId = routeId;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteItemDTO build();
  }
}
