package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.base.BaseRouteItemEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
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
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseRouteInstructionEntity<T extends BaseRouteInstructionEntity<T>>
  extends BaseRouteItemEntity<T>
    implements BaseRouteInstruction<RouteEntity>, Serializable
{

  @Column
  protected String instructionText = null;
  
  @Column
  protected String notes = null;
  

  

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
