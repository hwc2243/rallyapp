package com.rallyapp.rallymaster.model.base;

import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRouteInstruction
 extends BaseRouteItem, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public String getInstructionText ();
  public void setInstructionText (String instructionText);
  

  public String getNotes ();
  public void setNotes (String notes);
  

}
