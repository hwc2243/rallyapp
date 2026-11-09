package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Rally;
import com.rallyapp.rallymaster.model.Route;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRallyEntry<RALLY, ROUTE>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getDriverFirstName ();
  public void setDriverFirstName (String driverFirstName);
  

  public String getDriverLastName ();
  public void setDriverLastName (String driverLastName);
  

  public String getNavigatorFirstName ();
  public void setNavigatorFirstName (String navigatorFirstName);
  

  public String getNavigatorLastName ();
  public void setNavigatorLastName (String navigatorLastName);
  

  public Long getCarNumber ();
  public void setCarNumber (Long carNumber);
  

  public String getPrimaryDeviceId ();
  public void setPrimaryDeviceId (String primaryDeviceId);
  

  public String getBackupDeviceId ();
  public void setBackupDeviceId (String backupDeviceId);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public RALLY getRally ();
  public void setRally (RALLY rally);
  

  public ROUTE getRoute ();
  public void setRoute (ROUTE route);
  

}
