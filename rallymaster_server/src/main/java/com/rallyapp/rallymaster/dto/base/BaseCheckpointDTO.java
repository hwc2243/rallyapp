package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.base.BaseRouteItemDTO;
import com.rallyapp.rallymaster.dto.CheckpointDTO;
import com.rallyapp.rallymaster.model.base.BaseCheckpoint;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseCheckpointDTO
extends BaseRouteItemDTO
implements  Serializable
{
  protected Long id = null;

  protected CheckpointCheckpointType checkpointType = null;
  
  protected String name = null;
  
  protected String notes = null;
  
  protected Boolean competitorVisible = null;
  

  protected BaseCheckpointDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseCheckpointDTO (Builder builder)
  {
    this.id = builder.id;
    this.checkpointType = builder.checkpointType;
    this.name = builder.name;
    this.notes = builder.notes;
    this.competitorVisible = builder.competitorVisible;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public CheckpointCheckpointType getCheckpointType ()
  {
    return this.checkpointType;
  }
  
  public void setCheckpointType (CheckpointCheckpointType checkpointType)
  {
    this.checkpointType = checkpointType;
  }

  public String getName ()
  {
    return this.name;
  }
  
  public void setName (String name)
  {
    this.name = name;
  }
  

  public String getNotes ()
  {
    return this.notes;
  }
  
  public void setNotes (String notes)
  {
    this.notes = notes;
  }
  

  public Boolean getCompetitorVisible ()
  {
    return this.competitorVisible;
  }
  
  public void setCompetitorVisible (Boolean competitorVisible)
  {
    this.competitorVisible = competitorVisible;
  }
  


    @Override
	public int hashCode() {
		return Objects.hash(id);
	}
	
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
			
		BaseCheckpointDTO other = (BaseCheckpointDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private CheckpointCheckpointType checkpointType = null;
  
  private String name = null;
  
  private String notes = null;
  
  private Boolean competitorVisible = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder checkpointType(CheckpointCheckpointType checkpointType) {
      this.checkpointType = checkpointType;
      return this;
    }

    public Builder name(String name) {
      this.name = name;
      return this;
    }

    public Builder notes(String notes) {
      this.notes = notes;
      return this;
    }

    public Builder competitorVisible(Boolean competitorVisible) {
      this.competitorVisible = competitorVisible;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract CheckpointDTO build();
  }
}
