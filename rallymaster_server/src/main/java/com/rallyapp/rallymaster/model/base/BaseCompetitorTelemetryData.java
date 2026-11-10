package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.CompetitorTelemetry;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseCompetitorTelemetryData<COMPETITORTELEMETRY>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public LocalDateTime getCapturedAt ();
  public void setCapturedAt (LocalDateTime capturedAt);
  

  public Double getLatitude ();
  public void setLatitude (Double latitude);
  

  public Double getLongitude ();
  public void setLongitude (Double longitude);
  

  public Double getHeading ();
  public void setHeading (Double heading);
  

  public Double getSpeed ();
  public void setSpeed (Double speed);
  

  public Double getAccuracy ();
  public void setAccuracy (Double accuracy);
  

  public Double getDistanceToCheckpointMeters ();
  public void setDistanceToCheckpointMeters (Double distanceToCheckpointMeters);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public COMPETITORTELEMETRY getCompetitorTelemetry ();
  public void setCompetitorTelemetry (COMPETITORTELEMETRY competitorTelemetry);
  

}
