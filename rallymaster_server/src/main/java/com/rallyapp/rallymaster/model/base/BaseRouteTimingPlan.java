package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import com.rallyapp.rallymaster.model.RouteTimingPoint;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRouteTimingPlan<ROUTE, ROUTETIMINGPOINT>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public Long getVersion ();
  public void setVersion (Long version);
  

  public Long getCarZeroStartEpochMillis ();
  public void setCarZeroStartEpochMillis (Long carZeroStartEpochMillis);
  

  public RouteTimingPlanDistanceUnit getDistanceUnit ();
  public void setDistanceUnit (RouteTimingPlanDistanceUnit distanceUnit);
  

  public RouteTimingPlanScoringUnit getScoringUnit ();
  public void setScoringUnit (RouteTimingPlanScoringUnit scoringUnit);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public ROUTE getRoute ();
  public void setRoute (ROUTE route);


  public List<ROUTETIMINGPOINT> getPoints ();
  public void setPoints (List<ROUTETIMINGPOINT> points);


}
