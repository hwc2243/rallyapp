package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.OrganizationMembership;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseUser<ORGANIZATIONMEMBERSHIP>
 extends Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getEmailAddress ();
  public void setEmailAddress (String emailAddress);
  

  public String getFirstName ();
  public void setFirstName (String firstName);
  

  public String getLastName ();
  public void setLastName (String lastName);
  

  public Set<ORGANIZATIONMEMBERSHIP> getMemberships ();
  public void setMemberships (Set<ORGANIZATIONMEMBERSHIP> memberships);


}
