package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.entity.RouteItemEntity;
import com.rallyapp.rallymaster.model.base.BaseRouteInstruction;
import com.rallyapp.rallymaster.model.RouteInstruction;
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
