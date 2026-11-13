package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RouteInstructionDTO;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.model.base.BaseRouteInstruction;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteInstructionDTO
extends RouteItemDTO
implements  Serializable
{

  protected Long instructionNumber = null;
  
  protected String instructionText = null;
  
  protected RouteInstructionInstructionType instructionType = null;
  
  protected Double speed = null;
  
  protected Long pauseDurationMillis = null;
  
  protected Long transitDurationMillis = null;
  

  protected BaseRouteInstructionDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteInstructionDTO (Builder builder)
  {
    this.instructionNumber = builder.instructionNumber;
    this.instructionText = builder.instructionText;
    this.instructionType = builder.instructionType;
    this.speed = builder.speed;
    this.pauseDurationMillis = builder.pauseDurationMillis;
    this.transitDurationMillis = builder.transitDurationMillis;
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
  

  public RouteInstructionInstructionType getInstructionType ()
  {
    return this.instructionType;
  }
  
  public void setInstructionType (RouteInstructionInstructionType instructionType)
  {
    this.instructionType = instructionType;
  }

  public Double getSpeed ()
  {
    return this.speed;
  }
  
  public void setSpeed (Double speed)
  {
    this.speed = speed;
  }
  

  public Long getPauseDurationMillis ()
  {
    return this.pauseDurationMillis;
  }
  
  public void setPauseDurationMillis (Long pauseDurationMillis)
  {
    this.pauseDurationMillis = pauseDurationMillis;
  }
  

  public Long getTransitDurationMillis ()
  {
    return this.transitDurationMillis;
  }
  
  public void setTransitDurationMillis (Long transitDurationMillis)
  {
    this.transitDurationMillis = transitDurationMillis;
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

  public abstract static class Builder extends RouteItemDTO.Builder {


  private Long instructionNumber = null;
  
  private String instructionText = null;
  
  private RouteInstructionInstructionType instructionType = null;
  
  private Double speed = null;
  
  private Long pauseDurationMillis = null;
  
  private Long transitDurationMillis = null;
  


    
    public Builder instructionNumber(Long instructionNumber) {
      this.instructionNumber = instructionNumber;
      return this;
    }

    public Builder instructionText(String instructionText) {
      this.instructionText = instructionText;
      return this;
    }

    public Builder instructionType(RouteInstructionInstructionType instructionType) {
      this.instructionType = instructionType;
      return this;
    }

    public Builder speed(Double speed) {
      this.speed = speed;
      return this;
    }

    public Builder pauseDurationMillis(Long pauseDurationMillis) {
      this.pauseDurationMillis = pauseDurationMillis;
      return this;
    }

    public Builder transitDurationMillis(Long transitDurationMillis) {
      this.transitDurationMillis = transitDurationMillis;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteInstructionDTO build();
  }
}
