package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.model.base.BaseRoute;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RouteStatus;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected String name = null;
  
  protected String description = null;
  
  protected RouteStatus status = null;
  
  protected Double defaultSpeed = null;
  
  protected Long restartIntervalMillis = null;
  
  protected Long defaultPauseDurationMillis = null;
  
  protected String timeZone = null;
  
  protected Long carZeroStartEpochMillis = null;
  
  protected Long maximumCheckpointScore = null;
  
  protected Long organizationId = null;
  
  protected Long rallyId;




  protected BaseRouteDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteDTO (Builder builder)
  {
    this.id = builder.id;
    this.name = builder.name;
    this.description = builder.description;
    this.status = builder.status;
    this.defaultSpeed = builder.defaultSpeed;
    this.restartIntervalMillis = builder.restartIntervalMillis;
    this.defaultPauseDurationMillis = builder.defaultPauseDurationMillis;
    this.timeZone = builder.timeZone;
    this.carZeroStartEpochMillis = builder.carZeroStartEpochMillis;
    this.maximumCheckpointScore = builder.maximumCheckpointScore;
    this.organizationId = builder.organizationId;
    this.rallyId = builder.rallyId;
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
  

  public Long getRallyId ()
  {
    return this.rallyId;
  }

  public void setRallyId (Long rallyId)
  {
    this.rallyId = rallyId;
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
			
		BaseRouteDTO other = (BaseRouteDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String name = null;
  
  private String description = null;
  
  private RouteStatus status = null;
  
  private Double defaultSpeed = null;
  
  private Long restartIntervalMillis = null;
  
  private Long defaultPauseDurationMillis = null;
  
  private String timeZone = null;
  
  private Long carZeroStartEpochMillis = null;
  
  private Long maximumCheckpointScore = null;
  
  private Long organizationId = null;
  

    private Long rallyId = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder name(String name) {
      this.name = name;
      return this;
    }

    public Builder description(String description) {
      this.description = description;
      return this;
    }

    public Builder status(RouteStatus status) {
      this.status = status;
      return this;
    }

    public Builder defaultSpeed(Double defaultSpeed) {
      this.defaultSpeed = defaultSpeed;
      return this;
    }

    public Builder restartIntervalMillis(Long restartIntervalMillis) {
      this.restartIntervalMillis = restartIntervalMillis;
      return this;
    }

    public Builder defaultPauseDurationMillis(Long defaultPauseDurationMillis) {
      this.defaultPauseDurationMillis = defaultPauseDurationMillis;
      return this;
    }

    public Builder timeZone(String timeZone) {
      this.timeZone = timeZone;
      return this;
    }

    public Builder carZeroStartEpochMillis(Long carZeroStartEpochMillis) {
      this.carZeroStartEpochMillis = carZeroStartEpochMillis;
      return this;
    }

    public Builder maximumCheckpointScore(Long maximumCheckpointScore) {
      this.maximumCheckpointScore = maximumCheckpointScore;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    public Builder rallyId (Long rallyId) {
      this.rallyId = rallyId;
      return this;
    }
    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteDTO build();
  }
}
