package com.rallyapp.rallymaster.dto.base;


import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.model.base.BaseRoute;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteDTO
implements BaseRoute<RouteItemDTO>, Multitenant,  Serializable
{
  protected Long id = null;

  protected String name = null;
  
  protected String description = null;
  
  protected Long organizationId = null;
  
  protected Long rallyId;

  protected List<RouteItemDTO> items;


  protected BaseRouteDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteDTO (Builder builder)
  {
    this.id = builder.id;
    this.name = builder.name;
    this.description = builder.description;
    this.organizationId = builder.organizationId;
    this.rallyId = builder.rallyId;
    this.items = builder.items;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public String getName ()
  {
    return this.name;
  }
  
  public void setName (String name)
  {
    this.name = name;
  }
  

  public String getDescription ()
  {
    return this.description;
  }
  
  public void setDescription (String description)
  {
    this.description = description;
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

  public List<RouteItemDTO> getItems ()
  {
    return this.items;
  }
  
  public void setItems (List<RouteItemDTO> items)
  {
    this.items = items;
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
			
		BaseRouteDTO other = (BaseRouteDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String name = null;
  
  private String description = null;
  
  private Long organizationId = null;
  

    private Long rallyId = null;
    private List<RouteItemDTO> items = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder name(String name) {
      this.name = name;
      return this;
    }

    public Builder description(String description) {
      this.description = description;
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
    public Builder items(List<RouteItemDTO> items) {
      this.items = items;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteDTO build();
  }
}
