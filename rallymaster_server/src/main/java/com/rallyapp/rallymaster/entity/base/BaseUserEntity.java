package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.model.base.BaseUser;
import com.rallyapp.rallymaster.model.User;
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
public abstract class BaseUserEntity<T extends BaseUserEntity<T>> extends AbstractBaseEntity
    implements BaseUser<OrganizationMembershipEntity>, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected String emailAddress = null;
  
  @Column
  protected String firstName = null;
  
  @Column
  protected String lastName = null;
  

  @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
  protected Set<OrganizationMembershipEntity> memberships;
  
  
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
  

  public Set<OrganizationMembershipEntity> getMemberships ()
  {
    return this.memberships;
  }
  
  public void setMemberships (Set<OrganizationMembershipEntity> memberships)
  {
    this.memberships = memberships;
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
			
		BaseUserEntity other = (BaseUserEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
