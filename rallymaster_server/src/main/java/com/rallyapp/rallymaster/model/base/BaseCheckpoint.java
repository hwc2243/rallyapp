package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.model.Route;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseCheckpoint<ROUTE>
 extends BaseRouteItem<ROUTE>, Serializable
{ 
  public Long getId ();
  public void setId (Long id);


  public CheckpointCheckpointType getCheckpointType ();
  public void setCheckpointType (CheckpointCheckpointType checkpointType);
  

  public String getName ();
  public void setName (String name);
  

  public String getNotes ();
  public void setNotes (String notes);
  

  public Boolean getCompetitorVisible ();
  public void setCompetitorVisible (Boolean competitorVisible);
  

}
