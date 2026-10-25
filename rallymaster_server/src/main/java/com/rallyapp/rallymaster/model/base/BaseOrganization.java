package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.OrganizationMembership;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseOrganization<ORGANIZATIONMEMBERSHIP>
 extends Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getName ();
  public void setName (String name);
  

  public Set<ORGANIZATIONMEMBERSHIP> getMemberships ();
  public void setMemberships (Set<ORGANIZATIONMEMBERSHIP> memberships);


}
