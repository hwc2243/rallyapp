package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.User;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRally
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
  

  public Long getUserId ();
  public void setUserId (Long userId);

}
