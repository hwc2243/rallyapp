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
implements BaseRouteItem, Multitenant,  Serializable
{
  protected Long id = null;

  protected RouteItemItemType itemType = null;
  
  protected Long position = null;
  
  protected Long revision = null;
  
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
    this.revision = builder.revision;
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
  

  public Long getRevision ()
  {
    return this.revision;
  }
  
  public void setRevision (Long revision)
  {
    this.revision = revision;
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
  
  private Long revision = null;
  
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

    public Builder revision(Long revision) {
      this.revision = revision;
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
