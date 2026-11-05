package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.OrganizationEntity;
import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.model.base.BaseOrganizationMembership;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.OrganizationMembership;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
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
public abstract class BaseOrganizationMembershipEntity extends AbstractBaseEntity
    implements BaseOrganizationMembership<UserEntity, OrganizationEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  @Enumerated(EnumType.STRING)
  protected OrganizationMembershipRole role = null;
  
  @Column(insertable = false, updatable = false)
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "userId", nullable=true)
  protected UserEntity user;

  @ManyToOne
  @JoinColumn(name= "organizationId", nullable=true)
  protected OrganizationEntity organization;

  
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
  

  public UserEntity getUser ()
  {
    return this.user;
  }
  
  public void setUser (UserEntity user)
  {
    this.user = user;
  }


  public OrganizationEntity getOrganization ()
  {
    return this.organization;
  }
  
  public void setOrganization (OrganizationEntity organization)
  {
    this.organization = organization;
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
			
		BaseOrganizationMembershipEntity other = (BaseOrganizationMembershipEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
