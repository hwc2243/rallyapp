package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.User;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRally<USER, ROUTE>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getName ();
  public void setName (String name);
  

  public String getDescription ();
  public void setDescription (String description);
  

  public LocalDate getDate ();
  public void setDate (LocalDate date);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public USER getUser ();
  public void setUser (USER user);


  public List<ROUTE> getRoutes ();
  public void setRoutes (List<ROUTE> routes);


}
