package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Route;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseRouteInstruction<ROUTE>
 extends BaseRouteItem<ROUTE>, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public Long getInstructionNumber ();
  public void setInstructionNumber (Long instructionNumber);
  

  public String getInstructionText ();
  public void setInstructionText (String instructionText);
  

}
