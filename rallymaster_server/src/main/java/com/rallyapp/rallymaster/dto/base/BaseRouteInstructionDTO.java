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

  protected Long instructionNumber = null;
  
  protected String instructionText = null;
  

  protected BaseRouteInstructionDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteInstructionDTO (Builder builder)
  {
    this.id = builder.id;
    this.instructionNumber = builder.instructionNumber;
    this.instructionText = builder.instructionText;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public Long getInstructionNumber ()
  {
    return this.instructionNumber;
  }
  
  public void setInstructionNumber (Long instructionNumber)
  {
    this.instructionNumber = instructionNumber;
  }
  

  public String getInstructionText ()
  {
    return this.instructionText;
  }
  
  public void setInstructionText (String instructionText)
  {
    this.instructionText = instructionText;
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

  private Long instructionNumber = null;
  
  private String instructionText = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder instructionNumber(Long instructionNumber) {
      this.instructionNumber = instructionNumber;
      return this;
    }

    public Builder instructionText(String instructionText) {
      this.instructionText = instructionText;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteInstructionDTO build();
  }
}
