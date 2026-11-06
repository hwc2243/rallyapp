package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Organization;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import com.rallyapp.rallymaster.model.User;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseOrganizationMembership<USER, ORGANIZATION>
 extends Multitenant, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public OrganizationMembershipRole getRole ();
  public void setRole (OrganizationMembershipRole role);
  

  public Long getOrganizationId ();
  public void setOrganizationId (Long organizationId);
  

  public USER getUser ();
  public void setUser (USER user);
  

  public ORGANIZATION getOrganization ();
  public void setOrganization (ORGANIZATION organization);
  

}
