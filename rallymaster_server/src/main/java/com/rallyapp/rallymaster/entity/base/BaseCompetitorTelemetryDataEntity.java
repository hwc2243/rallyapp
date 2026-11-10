package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.model.base.BaseCompetitorTelemetryData;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.CompetitorTelemetryData;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseCompetitorTelemetryDataEntity extends AbstractBaseEntity
    implements BaseCompetitorTelemetryData<CompetitorTelemetryEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected LocalDateTime capturedAt = null;
  
  @Column
  protected Double latitude = null;
  
  @Column
  protected Double longitude = null;
  
  @Column
  protected Double heading = null;
  
  @Column
  protected Double speed = null;
  
  @Column
  protected Double accuracy = null;
  
  @Column
  protected Double distanceToCheckpointMeters = null;
  
  @Column
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "competitorTelemetryId", nullable=true)
  protected CompetitorTelemetryEntity competitorTelemetry;

  
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
  

  public LocalDateTime getCapturedAt ()
  {
    return this.capturedAt;
  }
  
  public void setCapturedAt (LocalDateTime capturedAt)
  {
    this.capturedAt = capturedAt;
  }
  

  public Double getLatitude ()
  {
    return this.latitude;
  }
  
  public void setLatitude (Double latitude)
  {
    this.latitude = latitude;
  }
  

  public Double getLongitude ()
  {
    return this.longitude;
  }
  
  public void setLongitude (Double longitude)
  {
    this.longitude = longitude;
  }
  

  public Double getHeading ()
  {
    return this.heading;
  }
  
  public void setHeading (Double heading)
  {
    this.heading = heading;
  }
  

  public Double getSpeed ()
  {
    return this.speed;
  }
  
  public void setSpeed (Double speed)
  {
    this.speed = speed;
  }
  

  public Double getAccuracy ()
  {
    return this.accuracy;
  }
  
  public void setAccuracy (Double accuracy)
  {
    this.accuracy = accuracy;
  }
  

  public Double getDistanceToCheckpointMeters ()
  {
    return this.distanceToCheckpointMeters;
  }
  
  public void setDistanceToCheckpointMeters (Double distanceToCheckpointMeters)
  {
    this.distanceToCheckpointMeters = distanceToCheckpointMeters;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public CompetitorTelemetryEntity getCompetitorTelemetry ()
  {
    return this.competitorTelemetry;
  }
  
  public void setCompetitorTelemetry (CompetitorTelemetryEntity competitorTelemetry)
  {
    this.competitorTelemetry = competitorTelemetry;
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
			
		BaseCompetitorTelemetryDataEntity other = (BaseCompetitorTelemetryDataEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
