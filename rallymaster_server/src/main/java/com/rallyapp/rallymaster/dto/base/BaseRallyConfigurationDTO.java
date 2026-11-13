package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RallyConfigurationDTO;
import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.model.base.BaseRallyConfiguration;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRallyConfigurationDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected RallyConfigurationDistanceUnit distanceUnit = null;
  
  protected RallyConfigurationScoringUnit scoringUnit = null;
  
  protected String eventPasswordHash = null;
  
  protected String timeZone = null;
  
  protected Long officialStartEpochMillis = null;
  
  protected Double checkpointAcquisitionRadiusMeters = null;
  
  protected Long maximumCheckpointScore = null;
  
  protected Long carStartIntervalMillis = null;
  
  protected Double defaultSpeed = null;
  
  protected Long defaultRestartIntervalMillis = null;
  
  protected Long defaultPauseDurationMillis = null;
  
  protected Long organizationId = null;
  
  protected Long rallyId;


  protected BaseRallyConfigurationDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRallyConfigurationDTO (Builder builder)
  {
    this.id = builder.id;
    this.distanceUnit = builder.distanceUnit;
    this.scoringUnit = builder.scoringUnit;
    this.eventPasswordHash = builder.eventPasswordHash;
    this.timeZone = builder.timeZone;
    this.officialStartEpochMillis = builder.officialStartEpochMillis;
    this.checkpointAcquisitionRadiusMeters = builder.checkpointAcquisitionRadiusMeters;
    this.maximumCheckpointScore = builder.maximumCheckpointScore;
    this.carStartIntervalMillis = builder.carStartIntervalMillis;
    this.defaultSpeed = builder.defaultSpeed;
    this.defaultRestartIntervalMillis = builder.defaultRestartIntervalMillis;
    this.defaultPauseDurationMillis = builder.defaultPauseDurationMillis;
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


  public RallyConfigurationDistanceUnit getDistanceUnit ()
  {
    return this.distanceUnit;
  }
  
  public void setDistanceUnit (RallyConfigurationDistanceUnit distanceUnit)
  {
    this.distanceUnit = distanceUnit;
  }

  public RallyConfigurationScoringUnit getScoringUnit ()
  {
    return this.scoringUnit;
  }
  
  public void setScoringUnit (RallyConfigurationScoringUnit scoringUnit)
  {
    this.scoringUnit = scoringUnit;
  }

  public String getEventPasswordHash ()
  {
    return this.eventPasswordHash;
  }
  
  public void setEventPasswordHash (String eventPasswordHash)
  {
    this.eventPasswordHash = eventPasswordHash;
  }
  

  public String getTimeZone ()
  {
    return this.timeZone;
  }
  
  public void setTimeZone (String timeZone)
  {
    this.timeZone = timeZone;
  }
  

  public Long getOfficialStartEpochMillis ()
  {
    return this.officialStartEpochMillis;
  }
  
  public void setOfficialStartEpochMillis (Long officialStartEpochMillis)
  {
    this.officialStartEpochMillis = officialStartEpochMillis;
  }
  

  public Double getCheckpointAcquisitionRadiusMeters ()
  {
    return this.checkpointAcquisitionRadiusMeters;
  }
  
  public void setCheckpointAcquisitionRadiusMeters (Double checkpointAcquisitionRadiusMeters)
  {
    this.checkpointAcquisitionRadiusMeters = checkpointAcquisitionRadiusMeters;
  }
  

  public Long getMaximumCheckpointScore ()
  {
    return this.maximumCheckpointScore;
  }
  
  public void setMaximumCheckpointScore (Long maximumCheckpointScore)
  {
    this.maximumCheckpointScore = maximumCheckpointScore;
  }
  

  public Long getCarStartIntervalMillis ()
  {
    return this.carStartIntervalMillis;
  }
  
  public void setCarStartIntervalMillis (Long carStartIntervalMillis)
  {
    this.carStartIntervalMillis = carStartIntervalMillis;
  }
  

  public Double getDefaultSpeed ()
  {
    return this.defaultSpeed;
  }
  
  public void setDefaultSpeed (Double defaultSpeed)
  {
    this.defaultSpeed = defaultSpeed;
  }
  

  public Long getDefaultRestartIntervalMillis ()
  {
    return this.defaultRestartIntervalMillis;
  }
  
  public void setDefaultRestartIntervalMillis (Long defaultRestartIntervalMillis)
  {
    this.defaultRestartIntervalMillis = defaultRestartIntervalMillis;
  }
  

  public Long getDefaultPauseDurationMillis ()
  {
    return this.defaultPauseDurationMillis;
  }
  
  public void setDefaultPauseDurationMillis (Long defaultPauseDurationMillis)
  {
    this.defaultPauseDurationMillis = defaultPauseDurationMillis;
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
			
		BaseRallyConfigurationDTO other = (BaseRallyConfigurationDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private RallyConfigurationDistanceUnit distanceUnit = null;
  
  private RallyConfigurationScoringUnit scoringUnit = null;
  
  private String eventPasswordHash = null;
  
  private String timeZone = null;
  
  private Long officialStartEpochMillis = null;
  
  private Double checkpointAcquisitionRadiusMeters = null;
  
  private Long maximumCheckpointScore = null;
  
  private Long carStartIntervalMillis = null;
  
  private Double defaultSpeed = null;
  
  private Long defaultRestartIntervalMillis = null;
  
  private Long defaultPauseDurationMillis = null;
  
  private Long organizationId = null;
  

    private Long rallyId = null;

    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder distanceUnit(RallyConfigurationDistanceUnit distanceUnit) {
      this.distanceUnit = distanceUnit;
      return this;
    }

    public Builder scoringUnit(RallyConfigurationScoringUnit scoringUnit) {
      this.scoringUnit = scoringUnit;
      return this;
    }

    public Builder eventPasswordHash(String eventPasswordHash) {
      this.eventPasswordHash = eventPasswordHash;
      return this;
    }

    public Builder timeZone(String timeZone) {
      this.timeZone = timeZone;
      return this;
    }

    public Builder officialStartEpochMillis(Long officialStartEpochMillis) {
      this.officialStartEpochMillis = officialStartEpochMillis;
      return this;
    }

    public Builder checkpointAcquisitionRadiusMeters(Double checkpointAcquisitionRadiusMeters) {
      this.checkpointAcquisitionRadiusMeters = checkpointAcquisitionRadiusMeters;
      return this;
    }

    public Builder maximumCheckpointScore(Long maximumCheckpointScore) {
      this.maximumCheckpointScore = maximumCheckpointScore;
      return this;
    }

    public Builder carStartIntervalMillis(Long carStartIntervalMillis) {
      this.carStartIntervalMillis = carStartIntervalMillis;
      return this;
    }

    public Builder defaultSpeed(Double defaultSpeed) {
      this.defaultSpeed = defaultSpeed;
      return this;
    }

    public Builder defaultRestartIntervalMillis(Long defaultRestartIntervalMillis) {
      this.defaultRestartIntervalMillis = defaultRestartIntervalMillis;
      return this;
    }

    public Builder defaultPauseDurationMillis(Long defaultPauseDurationMillis) {
      this.defaultPauseDurationMillis = defaultPauseDurationMillis;
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
    public abstract RallyConfigurationDTO build();
  }
}
