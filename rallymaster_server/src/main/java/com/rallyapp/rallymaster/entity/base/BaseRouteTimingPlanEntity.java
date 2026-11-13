package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.model.base.BaseRouteTimingPlan;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteTimingPlan;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
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
public abstract class BaseRouteTimingPlanEntity extends AbstractBaseEntity
    implements BaseRouteTimingPlan<RouteEntity, RouteTimingPointEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected Long version = null;
  
  @Column
  protected Long carZeroStartEpochMillis = null;
  
  @Column
  @Enumerated(EnumType.STRING)
  protected RouteTimingPlanDistanceUnit distanceUnit = null;
  
  @Column
  @Enumerated(EnumType.STRING)
  protected RouteTimingPlanScoringUnit scoringUnit = null;
  
  @Column
  protected Long organizationId = null;
  

  @OneToOne(cascade=CascadeType.ALL)
  @JoinColumn(name= "route_id", nullable=true)
  protected RouteEntity route;
  
  @OneToMany(mappedBy = "routeTimingPlan", cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
  protected List<RouteTimingPointEntity> points;
  
  
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
  

  public Long getVersion ()
  {
    return this.version;
  }
  
  public void setVersion (Long version)
  {
    this.version = version;
  }
  

  public Long getCarZeroStartEpochMillis ()
  {
    return this.carZeroStartEpochMillis;
  }
  
  public void setCarZeroStartEpochMillis (Long carZeroStartEpochMillis)
  {
    this.carZeroStartEpochMillis = carZeroStartEpochMillis;
  }
  

  public RouteTimingPlanDistanceUnit getDistanceUnit ()
  {
    return this.distanceUnit;
  }
  
  public void setDistanceUnit (RouteTimingPlanDistanceUnit distanceUnit)
  {
    this.distanceUnit = distanceUnit;
  }

  public RouteTimingPlanScoringUnit getScoringUnit ()
  {
    return this.scoringUnit;
  }
  
  public void setScoringUnit (RouteTimingPlanScoringUnit scoringUnit)
  {
    this.scoringUnit = scoringUnit;
  }

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public RouteEntity getRoute ()
  {
    return this.route;
  }
  
  public void setRoute (RouteEntity route)
  {
    this.route = route;
  }


  public List<RouteTimingPointEntity> getPoints ()
  {
    return this.points;
  }
  
  public void setPoints (List<RouteTimingPointEntity> points)
  {
    this.points = points;
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
			
		BaseRouteTimingPlanEntity other = (BaseRouteTimingPlanEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
