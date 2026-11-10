package com.rallyapp.rallymaster.entity.base;


import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.base.BaseCompetitorTelemetry;
import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.model.CompetitorTelemetry;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@MappedSuperclass
public abstract class BaseCompetitorTelemetryEntity extends AbstractBaseEntity
    implements BaseCompetitorTelemetry<RallyEntryEntity, RouteEntity, CheckpointEntity, CompetitorTelemetryDataEntity>, Multitenant, Serializable
{
  @Id
  @Column
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  protected Long id = null;

  @Column
  protected LocalDateTime occurredAt = null;
  
  @Column
  protected Double interceptLatitude = null;
  
  @Column
  protected Double interceptLongitude = null;
  
  @Column
  protected Double interceptHeading = null;
  
  @Column
  protected Double interceptSpeed = null;
  
  @Column
  protected Double interceptAccuracy = null;
  
  @Column
  protected Double closestDistanceMeters = null;
  
  @Column
  protected Long organizationId = null;
  

  @ManyToOne
  @JoinColumn(name= "rallyEntryId", nullable=true)
  protected RallyEntryEntity rallyEntry;

  @ManyToOne
  @JoinColumn(name= "routeId", nullable=true)
  protected RouteEntity route;

  @ManyToOne
  @JoinColumn(name= "checkpointId", nullable=true)
  protected CheckpointEntity checkpoint;

  @OneToMany(mappedBy = "competitorTelemetry", cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
  protected List<CompetitorTelemetryDataEntity> data;
  
  
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
  

  public LocalDateTime getOccurredAt ()
  {
    return this.occurredAt;
  }
  
  public void setOccurredAt (LocalDateTime occurredAt)
  {
    this.occurredAt = occurredAt;
  }
  

  public Double getInterceptLatitude ()
  {
    return this.interceptLatitude;
  }
  
  public void setInterceptLatitude (Double interceptLatitude)
  {
    this.interceptLatitude = interceptLatitude;
  }
  

  public Double getInterceptLongitude ()
  {
    return this.interceptLongitude;
  }
  
  public void setInterceptLongitude (Double interceptLongitude)
  {
    this.interceptLongitude = interceptLongitude;
  }
  

  public Double getInterceptHeading ()
  {
    return this.interceptHeading;
  }
  
  public void setInterceptHeading (Double interceptHeading)
  {
    this.interceptHeading = interceptHeading;
  }
  

  public Double getInterceptSpeed ()
  {
    return this.interceptSpeed;
  }
  
  public void setInterceptSpeed (Double interceptSpeed)
  {
    this.interceptSpeed = interceptSpeed;
  }
  

  public Double getInterceptAccuracy ()
  {
    return this.interceptAccuracy;
  }
  
  public void setInterceptAccuracy (Double interceptAccuracy)
  {
    this.interceptAccuracy = interceptAccuracy;
  }
  

  public Double getClosestDistanceMeters ()
  {
    return this.closestDistanceMeters;
  }
  
  public void setClosestDistanceMeters (Double closestDistanceMeters)
  {
    this.closestDistanceMeters = closestDistanceMeters;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
  }
  

  public RallyEntryEntity getRallyEntry ()
  {
    return this.rallyEntry;
  }
  
  public void setRallyEntry (RallyEntryEntity rallyEntry)
  {
    this.rallyEntry = rallyEntry;
  }


  public RouteEntity getRoute ()
  {
    return this.route;
  }
  
  public void setRoute (RouteEntity route)
  {
    this.route = route;
  }


  public CheckpointEntity getCheckpoint ()
  {
    return this.checkpoint;
  }
  
  public void setCheckpoint (CheckpointEntity checkpoint)
  {
    this.checkpoint = checkpoint;
  }


  public List<CompetitorTelemetryDataEntity> getData ()
  {
    return this.data;
  }
  
  public void setData (List<CompetitorTelemetryDataEntity> data)
  {
    this.data = data;
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
			
		BaseCompetitorTelemetryEntity other = (BaseCompetitorTelemetryEntity) obj;
		return Objects.equals(getId(), other.getId());
	}

}
