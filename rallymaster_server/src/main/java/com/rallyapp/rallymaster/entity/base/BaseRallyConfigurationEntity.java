package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.model.base.BaseRallyConfiguration;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.RallyConfiguration;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
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
public abstract class BaseRallyConfigurationEntity extends AbstractBaseEntity
    implements BaseRallyConfiguration<RallyEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  @Enumerated(EnumType.STRING)
  protected RallyConfigurationDistanceUnit distanceUnit = null;
  
  @Column
  @Enumerated(EnumType.STRING)
  protected RallyConfigurationScoringUnit scoringUnit = null;
  
  @Column
  protected String eventPasswordHash = null;
  
  @Column
  protected String timeZone = null;
  
  @Column
  protected Long officialStartEpochMillis = null;
  
  @Column
  protected Double checkpointAcquisitionRadiusMeters = null;
  
  @Column
  protected Long maximumCheckpointScore = null;
  
  @Column
  protected Long carStartIntervalMillis = null;
  
  @Column
  protected Double defaultSpeed = null;
  
  @Column
  protected Long defaultRestartIntervalMillis = null;
  
  @Column
  protected Long defaultPauseDurationMillis = null;
  
  @Column
  protected Long organizationId = null;
  

  @OneToOne(cascade=CascadeType.ALL)
  @JoinColumn(name= "rally_id", nullable=true)
  protected RallyEntity rally;
  
  
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
  

  public RallyEntity getRally ()
  {
    return this.rally;
  }
  
  public void setRally (RallyEntity rally)
  {
    this.rally = rally;
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
			
		BaseRallyConfigurationEntity other = (BaseRallyConfigurationEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
