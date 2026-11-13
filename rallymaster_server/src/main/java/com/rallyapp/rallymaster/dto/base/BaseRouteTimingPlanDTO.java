package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.model.base.BaseRouteTimingPlan;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteTimingPlanDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected Long version = null;
  
  protected Long carZeroStartEpochMillis = null;
  
  protected RouteTimingPlanDistanceUnit distanceUnit = null;
  
  protected RouteTimingPlanScoringUnit scoringUnit = null;
  
  protected Long organizationId = null;
  



  protected BaseRouteTimingPlanDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteTimingPlanDTO (Builder builder)
  {
    this.id = builder.id;
    this.version = builder.version;
    this.carZeroStartEpochMillis = builder.carZeroStartEpochMillis;
    this.distanceUnit = builder.distanceUnit;
    this.scoringUnit = builder.scoringUnit;
    this.organizationId = builder.organizationId;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
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
			
		BaseRouteTimingPlanDTO other = (BaseRouteTimingPlanDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private Long version = null;
  
  private Long carZeroStartEpochMillis = null;
  
  private RouteTimingPlanDistanceUnit distanceUnit = null;
  
  private RouteTimingPlanScoringUnit scoringUnit = null;
  
  private Long organizationId = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder version(Long version) {
      this.version = version;
      return this;
    }

    public Builder carZeroStartEpochMillis(Long carZeroStartEpochMillis) {
      this.carZeroStartEpochMillis = carZeroStartEpochMillis;
      return this;
    }

    public Builder distanceUnit(RouteTimingPlanDistanceUnit distanceUnit) {
      this.distanceUnit = distanceUnit;
      return this;
    }

    public Builder scoringUnit(RouteTimingPlanScoringUnit scoringUnit) {
      this.scoringUnit = scoringUnit;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteTimingPlanDTO build();
  }
}
