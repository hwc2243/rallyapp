package com.rallyapp.rallymaster.dto.base;


import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.model.base.BaseOrganization;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseOrganizationDTO
implements BaseOrganization<OrganizationMembershipDTO>,  Serializable
{
  protected Long id = null;

  protected String name = null;
  
  protected Set<OrganizationMembershipDTO> memberships;


  protected BaseOrganizationDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseOrganizationDTO (Builder builder)
  {
    this.id = builder.id;
    this.name = builder.name;
    this.memberships = builder.memberships;
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
  

  public Set<OrganizationMembershipDTO> getMemberships ()
  {
    return this.memberships;
  }
  
  public void setMemberships (Set<OrganizationMembershipDTO> memberships)
  {
    this.memberships = memberships;
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
			
		BaseOrganizationDTO other = (BaseOrganizationDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String name = null;
  

    private Set<OrganizationMembershipDTO> memberships = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder name(String name) {
      this.name = name;
      return this;
    }

    public Builder memberships(Set<OrganizationMembershipDTO> memberships) {
      this.memberships = memberships;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract OrganizationDTO build();
  }
}
