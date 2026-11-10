package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.model.base.BaseCompetitorTelemetryData;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseCompetitorTelemetryDataDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
  protected LocalDateTime capturedAt = null;
  
  protected Double latitude = null;
  
  protected Double longitude = null;
  
  protected Double heading = null;
  
  protected Double speed = null;
  
  protected Double accuracy = null;
  
  protected Double distanceToCheckpointMeters = null;
  
  protected Long organizationId = null;
  


  protected BaseCompetitorTelemetryDataDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseCompetitorTelemetryDataDTO (Builder builder)
  {
    this.id = builder.id;
    this.capturedAt = builder.capturedAt;
    this.latitude = builder.latitude;
    this.longitude = builder.longitude;
    this.heading = builder.heading;
    this.speed = builder.speed;
    this.accuracy = builder.accuracy;
    this.distanceToCheckpointMeters = builder.distanceToCheckpointMeters;
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
			
		BaseCompetitorTelemetryDataDTO other = (BaseCompetitorTelemetryDataDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private LocalDateTime capturedAt = null;
  
  private Double latitude = null;
  
  private Double longitude = null;
  
  private Double heading = null;
  
  private Double speed = null;
  
  private Double accuracy = null;
  
  private Double distanceToCheckpointMeters = null;
  
  private Long organizationId = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder capturedAt(LocalDateTime capturedAt) {
      this.capturedAt = capturedAt;
      return this;
    }

    public Builder latitude(Double latitude) {
      this.latitude = latitude;
      return this;
    }

    public Builder longitude(Double longitude) {
      this.longitude = longitude;
      return this;
    }

    public Builder heading(Double heading) {
      this.heading = heading;
      return this;
    }

    public Builder speed(Double speed) {
      this.speed = speed;
      return this;
    }

    public Builder accuracy(Double accuracy) {
      this.accuracy = accuracy;
      return this;
    }

    public Builder distanceToCheckpointMeters(Double distanceToCheckpointMeters) {
      this.distanceToCheckpointMeters = distanceToCheckpointMeters;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract CompetitorTelemetryDataDTO build();
  }
}
