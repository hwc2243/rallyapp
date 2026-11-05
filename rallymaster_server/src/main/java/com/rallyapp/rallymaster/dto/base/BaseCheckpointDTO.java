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

  protected Long checkpointNumber = null;
  
  protected CheckpointCheckpointType checkpointType = null;
  
  protected String name = null;
  

  protected BaseCheckpointDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseCheckpointDTO (Builder builder)
  {
    this.id = builder.id;
    this.checkpointNumber = builder.checkpointNumber;
    this.checkpointType = builder.checkpointType;
    this.name = builder.name;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public Long getCheckpointNumber ()
  {
    return this.checkpointNumber;
  }
  
  public void setCheckpointNumber (Long checkpointNumber)
  {
    this.checkpointNumber = checkpointNumber;
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

  private Long checkpointNumber = null;
  
  private CheckpointCheckpointType checkpointType = null;
  
  private String name = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder checkpointNumber(Long checkpointNumber) {
      this.checkpointNumber = checkpointNumber;
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

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract CheckpointDTO build();
  }
}
