package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Rally;
import com.rallyapp.rallymaster.model.RouteItem;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.model.RouteTimingPlan;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRoute<RALLY, ROUTEITEM, ROUTETIMINGPLAN>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getName ();
  public void setName (String name);
  

  public String getDescription ();
  public void setDescription (String description);
  

  public RouteStatus getStatus ();
  public void setStatus (RouteStatus status);
  

  public Double getDefaultSpeed ();
  public void setDefaultSpeed (Double defaultSpeed);
  

  public Long getRestartIntervalMillis ();
  public void setRestartIntervalMillis (Long restartIntervalMillis);
  

  public Long getDefaultPauseDurationMillis ();
  public void setDefaultPauseDurationMillis (Long defaultPauseDurationMillis);
  

  public String getTimeZone ();
  public void setTimeZone (String timeZone);
  

  public Long getCarZeroStartEpochMillis ();
  public void setCarZeroStartEpochMillis (Long carZeroStartEpochMillis);
  

  public Long getMaximumCheckpointScore ();
  public void setMaximumCheckpointScore (Long maximumCheckpointScore);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLY getRally ();
  public void setRally (RALLY rally);
  

  public List<ROUTEITEM> getItems ();
  public void setItems (List<ROUTEITEM> items);


  public ROUTETIMINGPLAN getTimingPlan ();
  public void setTimingPlan (ROUTETIMINGPLAN timingPlan);


}
