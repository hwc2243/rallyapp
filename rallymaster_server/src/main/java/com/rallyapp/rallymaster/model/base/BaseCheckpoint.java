package com.rallyapp.rallymaster.model.base;

import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface BaseCheckpoint
 extends BaseRouteItem, Serializable
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
