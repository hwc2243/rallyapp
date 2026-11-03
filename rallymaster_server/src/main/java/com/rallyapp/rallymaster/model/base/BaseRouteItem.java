package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.RouteItemItemType;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRouteItem<ROUTE>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public RouteItemItemType getItemType ();
  public void setItemType (RouteItemItemType itemType);
  

  public Long getPosition ();
  public void setPosition (Long position);
  

  public Long getRevision ();
  public void setRevision (Long revision);
  

  public Boolean getDeleted ();
  public void setDeleted (Boolean deleted);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public ROUTE getRoute ();
  public void setRoute (ROUTE route);
  

}
