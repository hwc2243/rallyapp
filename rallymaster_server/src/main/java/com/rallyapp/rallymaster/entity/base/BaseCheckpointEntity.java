package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.base.BaseRouteItemEntity;
import com.rallyapp.rallymaster.model.base.BaseCheckpoint;
import com.rallyapp.rallymaster.model.Checkpoint;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
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
public abstract class BaseCheckpointEntity<T extends BaseCheckpointEntity<T>>
  extends BaseRouteItemEntity<T>
    implements BaseCheckpoint, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  @Enumerated(EnumType.STRING)
  protected CheckpointCheckpointType checkpointType = null;
  
  @Column
  protected String name = null;
  
  @Column
  protected String notes = null;
  
  @Column
  protected Boolean competitorVisible = null;
  

  
  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }

  public Object getKey ()
  {
    return this.id;
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
			
		BaseCheckpointEntity other = (BaseCheckpointEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
