package com.rallyapp.rallymaster.dto.base;


import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.OrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.model.base.BaseUser;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseUserDTO
implements BaseUser<OrganizationMembershipDTO>,  Serializable
{
  protected Long id = null;

  protected String emailAddress = null;
  
  protected String firstName = null;
  
  protected String lastName = null;
  
  protected Set<OrganizationMembershipDTO> memberships;


  protected BaseUserDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseUserDTO (Builder builder)
  {
    this.id = builder.id;
    this.emailAddress = builder.emailAddress;
    this.firstName = builder.firstName;
    this.lastName = builder.lastName;
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


  public String getEmailAddress ()
  {
    return this.emailAddress;
  }
  
  public void setEmailAddress (String emailAddress)
  {
    this.emailAddress = emailAddress;
  }
  

  public String getFirstName ()
  {
    return this.firstName;
  }
  
  public void setFirstName (String firstName)
  {
    this.firstName = firstName;
  }
  

  public String getLastName ()
  {
    return this.lastName;
  }
  
  public void setLastName (String lastName)
  {
    this.lastName = lastName;
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
			
		BaseUserDTO other = (BaseUserDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String emailAddress = null;
  
  private String firstName = null;
  
  private String lastName = null;
  

    private Set<OrganizationMembershipDTO> memberships = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder emailAddress(String emailAddress) {
      this.emailAddress = emailAddress;
      return this;
    }

    public Builder firstName(String firstName) {
      this.firstName = firstName;
      return this;
    }

    public Builder lastName(String lastName) {
      this.lastName = lastName;
      return this;
    }

    public Builder memberships(Set<OrganizationMembershipDTO> memberships) {
      this.memberships = memberships;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract UserDTO build();
  }
}
