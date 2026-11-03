package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.base.BaseRouteItemDTO;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.model.base.BaseRouteInstruction;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteInstructionDTO
extends BaseRouteItemDTO
implements  Serializable
{
  protected Long id = null;

  protected String instructionText = null;
  
  protected String notes = null;
  

  protected BaseRouteInstructionDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteInstructionDTO (Builder builder)
  {
    this.id = builder.id;
    this.instructionText = builder.instructionText;
    this.notes = builder.notes;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public String getInstructionText ()
  {
    return this.instructionText;
  }
  
  public void setInstructionText (String instructionText)
  {
    this.instructionText = instructionText;
  }
  

  public String getNotes ()
  {
    return this.notes;
  }
  
  public void setNotes (String notes)
  {
    this.notes = notes;
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
			
		BaseRouteInstructionDTO other = (BaseRouteInstructionDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private String instructionText = null;
  
  private String notes = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder instructionText(String instructionText) {
      this.instructionText = instructionText;
      return this;
    }

    public Builder notes(String notes) {
      this.notes = notes;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteInstructionDTO build();
  }
}
