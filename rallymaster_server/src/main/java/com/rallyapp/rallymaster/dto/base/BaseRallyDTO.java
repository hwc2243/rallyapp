package com.rallyapp.rallymaster.dto.base;


import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.model.base.BaseRally;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRallyDTO
implements BaseRally, Multitenant,  Serializable
{
  protected Long id = null;

  protected String name = null;
  
  protected String description = null;
  
  protected LocalDate date = null;
  
  protected Long organizationId = null;
  
  protected Long userId;


  protected BaseRallyDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRallyDTO (Builder builder)
  {
    this.id = builder.id;
    this.name = builder.name;
    this.description = builder.description;
    this.date = builder.date;
    this.organizationId = builder.organizationId;
    this.userId = builder.userId;
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
  

  public LocalDate getDate ()
  {
    return this.date;
  }
  
  public void setDate (LocalDate date)
  {
    this.date = date;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public Long getUserId ()
  {
    return this.userId;
  }

  public void setUserId (Long userId)
  {
    this.userId = userId;
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
			
		BaseRallyDTO other = (BaseRallyDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String name = null;
  
  private String description = null;
  
  private LocalDate date = null;
  
  private Long organizationId = null;
  

    private Long userId = null;

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

    public Builder date(LocalDate date) {
      this.date = date;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    public Builder userId (Long userId) {
      this.userId = userId;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RallyDTO build();
  }
}
