package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Rally;
import com.rallyapp.rallymaster.model.RouteItem;
import com.rallyapp.rallymaster.model.RouteStatus;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRoute<RALLY, ROUTEITEM>
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
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLY getRally ();
  public void setRally (RALLY rally);
  

  public List<ROUTEITEM> getItems ();
  public void setItems (List<ROUTEITEM> items);


}
