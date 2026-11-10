package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDTO;
import com.rallyapp.rallymaster.dto.RallyEntryDTO;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.model.base.BaseCompetitorTelemetry;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseCompetitorTelemetryDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
  protected LocalDateTime occurredAt = null;
  
  protected Double interceptLatitude = null;
  
  protected Double interceptLongitude = null;
  
  protected Double interceptHeading = null;
  
  protected Double interceptSpeed = null;
  
  protected Double interceptAccuracy = null;
  
  protected Double closestDistanceMeters = null;
  
  protected Long organizationId = null;
  





  protected BaseCompetitorTelemetryDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseCompetitorTelemetryDTO (Builder builder)
  {
    this.id = builder.id;
    this.occurredAt = builder.occurredAt;
    this.interceptLatitude = builder.interceptLatitude;
    this.interceptLongitude = builder.interceptLongitude;
    this.interceptHeading = builder.interceptHeading;
    this.interceptSpeed = builder.interceptSpeed;
    this.interceptAccuracy = builder.interceptAccuracy;
    this.closestDistanceMeters = builder.closestDistanceMeters;
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


  public LocalDateTime getOccurredAt ()
  {
    return this.occurredAt;
  }
  
  public void setOccurredAt (LocalDateTime occurredAt)
  {
    this.occurredAt = occurredAt;
  }
  

  public Double getInterceptLatitude ()
  {
    return this.interceptLatitude;
  }
  
  public void setInterceptLatitude (Double interceptLatitude)
  {
    this.interceptLatitude = interceptLatitude;
  }
  

  public Double getInterceptLongitude ()
  {
    return this.interceptLongitude;
  }
  
  public void setInterceptLongitude (Double interceptLongitude)
  {
    this.interceptLongitude = interceptLongitude;
  }
  

  public Double getInterceptHeading ()
  {
    return this.interceptHeading;
  }
  
  public void setInterceptHeading (Double interceptHeading)
  {
    this.interceptHeading = interceptHeading;
  }
  

  public Double getInterceptSpeed ()
  {
    return this.interceptSpeed;
  }
  
  public void setInterceptSpeed (Double interceptSpeed)
  {
    this.interceptSpeed = interceptSpeed;
  }
  

  public Double getInterceptAccuracy ()
  {
    return this.interceptAccuracy;
  }
  
  public void setInterceptAccuracy (Double interceptAccuracy)
  {
    this.interceptAccuracy = interceptAccuracy;
  }
  

  public Double getClosestDistanceMeters ()
  {
    return this.closestDistanceMeters;
  }
  
  public void setClosestDistanceMeters (Double closestDistanceMeters)
  {
    this.closestDistanceMeters = closestDistanceMeters;
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
			
		BaseCompetitorTelemetryDTO other = (BaseCompetitorTelemetryDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private LocalDateTime occurredAt = null;
  
  private Double interceptLatitude = null;
  
  private Double interceptLongitude = null;
  
  private Double interceptHeading = null;
  
  private Double interceptSpeed = null;
  
  private Double interceptAccuracy = null;
  
  private Double closestDistanceMeters = null;
  
  private Long organizationId = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder occurredAt(LocalDateTime occurredAt) {
      this.occurredAt = occurredAt;
      return this;
    }

    public Builder interceptLatitude(Double interceptLatitude) {
      this.interceptLatitude = interceptLatitude;
      return this;
    }

    public Builder interceptLongitude(Double interceptLongitude) {
      this.interceptLongitude = interceptLongitude;
      return this;
    }

    public Builder interceptHeading(Double interceptHeading) {
      this.interceptHeading = interceptHeading;
      return this;
    }

    public Builder interceptSpeed(Double interceptSpeed) {
      this.interceptSpeed = interceptSpeed;
      return this;
    }

    public Builder interceptAccuracy(Double interceptAccuracy) {
      this.interceptAccuracy = interceptAccuracy;
      return this;
    }

    public Builder closestDistanceMeters(Double closestDistanceMeters) {
      this.closestDistanceMeters = closestDistanceMeters;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract CompetitorTelemetryDTO build();
  }
}
