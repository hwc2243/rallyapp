package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
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
  

  public RouteInstructionInstructionType getInstructionType ();
  public void setInstructionType (RouteInstructionInstructionType instructionType);
  

  public Double getSpeed ();
  public void setSpeed (Double speed);
  

  public Long getPauseDurationMillis ();
  public void setPauseDurationMillis (Long pauseDurationMillis);
  

  public Long getTransitDurationMillis ();
  public void setTransitDurationMillis (Long transitDurationMillis);
  

}
