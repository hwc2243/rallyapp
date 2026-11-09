package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Rally;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRallyConfiguration<RALLY>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public RallyConfigurationScoringUnit getScoringUnit ();
  public void setScoringUnit (RallyConfigurationScoringUnit scoringUnit);
  

  public String getEventPasswordHash ();
  public void setEventPasswordHash (String eventPasswordHash);
  

  public String getTimeZone ();
  public void setTimeZone (String timeZone);
  

  public LocalDateTime getOfficialStartTime ();
  public void setOfficialStartTime (LocalDateTime officialStartTime);
  

  public Double getCheckpointAcquisitionRadiusMeters ();
  public void setCheckpointAcquisitionRadiusMeters (Double checkpointAcquisitionRadiusMeters);
  

  public Long getMaximumCheckpointScore ();
  public void setMaximumCheckpointScore (Long maximumCheckpointScore);
  

  public Long getStartIntervalSeconds ();
  public void setStartIntervalSeconds (Long startIntervalSeconds);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLY getRally ();
  public void setRally (RALLY rally);


}
