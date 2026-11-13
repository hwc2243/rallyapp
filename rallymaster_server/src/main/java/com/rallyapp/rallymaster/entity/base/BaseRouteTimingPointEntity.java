package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.base.BaseRouteTimingPoint;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteTimingPoint;
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
public abstract class BaseRouteTimingPointEntity extends AbstractBaseEntity
    implements BaseRouteTimingPoint<RouteTimingPlanEntity, RouteItemEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected Long segmentNumber = null;
  
  @Column
  protected Long segmentOffsetMillis = null;
  
  @Column
  protected Long carZeroSegmentStartEpochMillis = null;
  
  @Column
  protected Long carZeroIdealArrivalEpochMillis = null;
  
  @Column
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "routeTimingPlanId", nullable=true)
  protected RouteTimingPlanEntity routeTimingPlan;

  @ManyToOne
  @JoinColumn(name= "routeItemId", nullable=true)
  protected RouteItemEntity routeItem;

  
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
  

  public Long getSegmentNumber ()
  {
    return this.segmentNumber;
  }
  
  public void setSegmentNumber (Long segmentNumber)
  {
    this.segmentNumber = segmentNumber;
  }
  

  public Long getSegmentOffsetMillis ()
  {
    return this.segmentOffsetMillis;
  }
  
  public void setSegmentOffsetMillis (Long segmentOffsetMillis)
  {
    this.segmentOffsetMillis = segmentOffsetMillis;
  }
  

  public Long getCarZeroSegmentStartEpochMillis ()
  {
    return this.carZeroSegmentStartEpochMillis;
  }
  
  public void setCarZeroSegmentStartEpochMillis (Long carZeroSegmentStartEpochMillis)
  {
    this.carZeroSegmentStartEpochMillis = carZeroSegmentStartEpochMillis;
  }
  

  public Long getCarZeroIdealArrivalEpochMillis ()
  {
    return this.carZeroIdealArrivalEpochMillis;
  }
  
  public void setCarZeroIdealArrivalEpochMillis (Long carZeroIdealArrivalEpochMillis)
  {
    this.carZeroIdealArrivalEpochMillis = carZeroIdealArrivalEpochMillis;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public RouteTimingPlanEntity getRouteTimingPlan ()
  {
    return this.routeTimingPlan;
  }
  
  public void setRouteTimingPlan (RouteTimingPlanEntity routeTimingPlan)
  {
    this.routeTimingPlan = routeTimingPlan;
  }


  public RouteItemEntity getRouteItem ()
  {
    return this.routeItem;
  }
  
  public void setRouteItem (RouteItemEntity routeItem)
  {
    this.routeItem = routeItem;
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
			
		BaseRouteTimingPointEntity other = (BaseRouteTimingPointEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
