package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.UserEntity;
import com.rallyapp.rallymaster.model.base.BaseRally;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.Rally;
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
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseRallyEntity<T extends BaseRallyEntity<T>> extends AbstractBaseEntity
    implements BaseRally, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected String name = null;
  
  @Column
  protected String description = null;
  
  @Column
  protected LocalDate date = null;
  
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
			
		BaseRallyEntity other = (BaseRallyEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
