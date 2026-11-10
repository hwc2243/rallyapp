package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Checkpoint;
import com.rallyapp.rallymaster.model.CompetitorTelemetryData;
import com.rallyapp.rallymaster.model.RallyEntry;
import com.rallyapp.rallymaster.model.Route;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseCompetitorTelemetry<RALLYENTRY, ROUTE, CHECKPOINT, COMPETITORTELEMETRYDATA>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public LocalDateTime getOccurredAt ();
  public void setOccurredAt (LocalDateTime occurredAt);
  

  public Double getInterceptLatitude ();
  public void setInterceptLatitude (Double interceptLatitude);
  

  public Double getInterceptLongitude ();
  public void setInterceptLongitude (Double interceptLongitude);
  

  public Double getInterceptHeading ();
  public void setInterceptHeading (Double interceptHeading);
  

  public Double getInterceptSpeed ();
  public void setInterceptSpeed (Double interceptSpeed);
  

  public Double getInterceptAccuracy ();
  public void setInterceptAccuracy (Double interceptAccuracy);
  

  public Double getClosestDistanceMeters ();
  public void setClosestDistanceMeters (Double closestDistanceMeters);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLYENTRY getRallyEntry ();
  public void setRallyEntry (RALLYENTRY rallyEntry);
  

  public ROUTE getRoute ();
  public void setRoute (ROUTE route);
  

  public CHECKPOINT getCheckpoint ();
  public void setCheckpoint (CHECKPOINT checkpoint);
  

  public List<COMPETITORTELEMETRYDATA> getData ();
  public void setData (List<COMPETITORTELEMETRYDATA> data);


}
