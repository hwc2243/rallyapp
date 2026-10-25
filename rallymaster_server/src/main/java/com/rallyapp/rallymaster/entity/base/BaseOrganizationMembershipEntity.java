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
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseOrganizationMembershipEntity<T extends BaseOrganizationMembershipEntity<T>> extends AbstractBaseEntity
    implements BaseOrganizationMembership, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  @Enumerated(EnumType.STRING)
  protected OrganizationMembershipRole role = null;
  
  @Column
  protected Long organizationId = null;
  

  @Column(name = "userId")
  protected Long userId = null;

  
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
