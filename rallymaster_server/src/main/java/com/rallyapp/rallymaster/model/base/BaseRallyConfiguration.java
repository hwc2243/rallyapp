package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Rally;
import com.rallyapp.rallymaster.model.RallyConfigurationDistanceUnit;
import com.rallyapp.rallymaster.model.RallyConfigurationScoringUnit;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRallyConfiguration<RALLY>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public RallyConfigurationDistanceUnit getDistanceUnit ();
  public void setDistanceUnit (RallyConfigurationDistanceUnit distanceUnit);
  

  public RallyConfigurationScoringUnit getScoringUnit ();
  public void setScoringUnit (RallyConfigurationScoringUnit scoringUnit);
  

  public String getEventPasswordHash ();
  public void setEventPasswordHash (String eventPasswordHash);
  

  public String getTimeZone ();
  public void setTimeZone (String timeZone);
  

  public Long getOfficialStartEpochMillis ();
  public void setOfficialStartEpochMillis (Long officialStartEpochMillis);
  

  public Double getCheckpointAcquisitionRadiusMeters ();
  public void setCheckpointAcquisitionRadiusMeters (Double checkpointAcquisitionRadiusMeters);
  

  public Long getMaximumCheckpointScore ();
  public void setMaximumCheckpointScore (Long maximumCheckpointScore);
  

  public Long getCarStartIntervalMillis ();
  public void setCarStartIntervalMillis (Long carStartIntervalMillis);
  

  public Double getDefaultSpeed ();
  public void setDefaultSpeed (Double defaultSpeed);
  

  public Long getDefaultRestartIntervalMillis ();
  public void setDefaultRestartIntervalMillis (Long defaultRestartIntervalMillis);
  

  public Long getDefaultPauseDurationMillis ();
  public void setDefaultPauseDurationMillis (Long defaultPauseDurationMillis);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLY getRally ();
  public void setRally (RALLY rally);


}
