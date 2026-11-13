package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.RouteItem;
import com.rallyapp.rallymaster.model.RouteTimingPlan;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRouteTimingPoint<ROUTETIMINGPLAN, ROUTEITEM>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public Long getSegmentNumber ();
  public void setSegmentNumber (Long segmentNumber);
  

  public Long getSegmentOffsetMillis ();
  public void setSegmentOffsetMillis (Long segmentOffsetMillis);
  

  public Long getCarZeroSegmentStartEpochMillis ();
  public void setCarZeroSegmentStartEpochMillis (Long carZeroSegmentStartEpochMillis);
  

  public Long getCarZeroIdealArrivalEpochMillis ();
  public void setCarZeroIdealArrivalEpochMillis (Long carZeroIdealArrivalEpochMillis);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public ROUTETIMINGPLAN getRouteTimingPlan ();
  public void setRouteTimingPlan (ROUTETIMINGPLAN routeTimingPlan);
  

  public ROUTEITEM getRouteItem ();
  public void setRouteItem (ROUTEITEM routeItem);
  

}
