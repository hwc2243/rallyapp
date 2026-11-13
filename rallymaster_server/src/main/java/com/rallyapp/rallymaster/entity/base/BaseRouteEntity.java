package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.base.BaseRoute;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.RouteStatus;
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
public abstract class BaseRouteEntity extends AbstractBaseEntity
    implements BaseRoute<RallyEntity, RouteItemEntity, RouteTimingPlanEntity>, Multitenant, Serializable
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
  @Enumerated(EnumType.STRING)
  protected RouteStatus status = null;
  
  @Column
  protected Double defaultSpeed = null;
  
  @Column
  protected Long restartIntervalMillis = null;
  
  @Column
  protected Long defaultPauseDurationMillis = null;
  
  @Column
  protected String timeZone = null;
  
  @Column
  protected Long carZeroStartEpochMillis = null;
  
  @Column
  protected Long maximumCheckpointScore = null;
  
  @Column
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "rallyId", nullable=true)
  protected RallyEntity rally;

  @OneToMany(mappedBy = "route", cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
  @OrderBy("position ASC")
  protected List<RouteItemEntity> items;
  
  @OneToOne(cascade=CascadeType.ALL)
  @JoinColumn(name= "timingPlan_id", nullable=true)
  protected RouteTimingPlanEntity timingPlan;
  
  
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
  

  public RouteStatus getStatus ()
  {
    return this.status;
  }
  
  public void setStatus (RouteStatus status)
  {
    this.status = status;
  }

  public Double getDefaultSpeed ()
  {
    return this.defaultSpeed;
  }
  
  public void setDefaultSpeed (Double defaultSpeed)
  {
    this.defaultSpeed = defaultSpeed;
  }
  

  public Long getRestartIntervalMillis ()
  {
    return this.restartIntervalMillis;
  }
  
  public void setRestartIntervalMillis (Long restartIntervalMillis)
  {
    this.restartIntervalMillis = restartIntervalMillis;
  }
  

  public Long getDefaultPauseDurationMillis ()
  {
    return this.defaultPauseDurationMillis;
  }
  
  public void setDefaultPauseDurationMillis (Long defaultPauseDurationMillis)
  {
    this.defaultPauseDurationMillis = defaultPauseDurationMillis;
  }
  

  public String getTimeZone ()
  {
    return this.timeZone;
  }
  
  public void setTimeZone (String timeZone)
  {
    this.timeZone = timeZone;
  }
  

  public Long getCarZeroStartEpochMillis ()
  {
    return this.carZeroStartEpochMillis;
  }
  
  public void setCarZeroStartEpochMillis (Long carZeroStartEpochMillis)
  {
    this.carZeroStartEpochMillis = carZeroStartEpochMillis;
  }
  

  public Long getMaximumCheckpointScore ()
  {
    return this.maximumCheckpointScore;
  }
  
  public void setMaximumCheckpointScore (Long maximumCheckpointScore)
  {
    this.maximumCheckpointScore = maximumCheckpointScore;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public RallyEntity getRally ()
  {
    return this.rally;
  }
  
  public void setRally (RallyEntity rally)
  {
    this.rally = rally;
  }


  public List<RouteItemEntity> getItems ()
  {
    return this.items;
  }
  
  public void setItems (List<RouteItemEntity> items)
  {
    this.items = items;
  }


  public RouteTimingPlanEntity getTimingPlan ()
  {
    return this.timingPlan;
  }
  
  public void setTimingPlan (RouteTimingPlanEntity timingPlan)
  {
    this.timingPlan = timingPlan;
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
			
		BaseRouteEntity other = (BaseRouteEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
