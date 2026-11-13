package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.model.base.BaseRouteInstruction;
import com.rallyapp.rallymaster.model.RouteInstruction;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseRouteInstructionEntity
  extends RouteItemEntity
    implements BaseRouteInstruction<RouteEntity>, Serializable
{

  @Column
  protected Long instructionNumber = null;
  
  @Column
  protected String instructionText = null;
  
  @Column
  @Enumerated(EnumType.STRING)
  protected RouteInstructionInstructionType instructionType = null;
  
  @Column
  protected Double speed = null;
  
  @Column
  protected Long pauseDurationMillis = null;
  
  @Column
  protected Long transitDurationMillis = null;
  

  

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
		return Objects.hash(this.getId());
	}
	
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
			
		BaseRouteInstructionEntity other = (BaseRouteInstructionEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
