package com.rallyapp.rallymaster.dto.base;


import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.model.base.BaseOrganizationMembership;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseOrganizationMembershipDTO
implements BaseOrganizationMembership, Multitenant,  Serializable
{
  protected Long id = null;

  protected OrganizationMembershipRole role = null;
  
  protected Long organizationId = null;
  
  protected Long userId;



  protected BaseOrganizationMembershipDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseOrganizationMembershipDTO (Builder builder)
  {
    this.id = builder.id;
    this.role = builder.role;
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


  public OrganizationMembershipRole getRole ()
  {
    return this.role;
  }
  
  public void setRole (OrganizationMembershipRole role)
  {
    this.role = role;
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
			
		BaseOrganizationMembershipDTO other = (BaseOrganizationMembershipDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private OrganizationMembershipRole role = null;
  
  private Long organizationId = null;
  

    private Long userId = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder role(OrganizationMembershipRole role) {
      this.role = role;
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
    public abstract OrganizationMembershipDTO build();
  }
}
