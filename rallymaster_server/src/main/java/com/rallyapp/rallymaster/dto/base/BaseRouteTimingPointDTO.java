package com.rallyapp.rallymaster.dto.base;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.rallyapp.rallymaster.dto.RouteItemDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPlanDTO;
import com.rallyapp.rallymaster.dto.RouteTimingPointDTO;
import com.rallyapp.rallymaster.model.base.BaseRouteTimingPoint;
import com.rallyapp.rallymaster.model.base.Multitenant;
import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public abstract class BaseRouteTimingPointDTO
implements Multitenant,  Serializable
{
  protected Long id = null;

  protected Long segmentNumber = null;
  
  protected Long segmentOffsetMillis = null;
  
  protected Long carZeroSegmentStartEpochMillis = null;
  
  protected Long carZeroIdealArrivalEpochMillis = null;
  
  protected Long organizationId = null;
  



  protected BaseRouteTimingPointDTO () {
  }
  
  // Private constructor to force the use of the Builder
  protected BaseRouteTimingPointDTO (Builder builder)
  {
    this.id = builder.id;
    this.segmentNumber = builder.segmentNumber;
    this.segmentOffsetMillis = builder.segmentOffsetMillis;
    this.carZeroSegmentStartEpochMillis = builder.carZeroSegmentStartEpochMillis;
    this.carZeroIdealArrivalEpochMillis = builder.carZeroIdealArrivalEpochMillis;
    this.organizationId = builder.organizationId;
  }

  public Long getId ()
  {
    return this.id;
  }
  
  public void setId (Long id)
  {
    this.id = id;
  }


  public Long getSegmentNumber ()
  {
    return this.segmentNumber;
  }
  
  public void setSegmentNumber (Long segmentNumber)
  {
    this.segmentNumber = segmentNumber;
  }
  

  public Long getSegmentOffsetMillis ()
  {
    return this.segmentOffsetMillis;
  }
  
  public void setSegmentOffsetMillis (Long segmentOffsetMillis)
  {
    this.segmentOffsetMillis = segmentOffsetMillis;
  }
  

  public Long getCarZeroSegmentStartEpochMillis ()
  {
    return this.carZeroSegmentStartEpochMillis;
  }
  
  public void setCarZeroSegmentStartEpochMillis (Long carZeroSegmentStartEpochMillis)
  {
    this.carZeroSegmentStartEpochMillis = carZeroSegmentStartEpochMillis;
  }
  

  public Long getCarZeroIdealArrivalEpochMillis ()
  {
    return this.carZeroIdealArrivalEpochMillis;
  }
  
  public void setCarZeroIdealArrivalEpochMillis (Long carZeroIdealArrivalEpochMillis)
  {
    this.carZeroIdealArrivalEpochMillis = carZeroIdealArrivalEpochMillis;
  }
  

  public Long getOrganizationId ()
  {
    return this.organizationId;
  }
  
  public void setOrganizationId (Long organizationId)
  {
    this.organizationId = organizationId;
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
			
		BaseRouteTimingPointDTO other = (BaseRouteTimingPointDTO) obj;
		return id == other.id;
	}

  public abstract static class Builder {

  private Long id = null;

  private Long segmentNumber = null;
  
  private Long segmentOffsetMillis = null;
  
  private Long carZeroSegmentStartEpochMillis = null;
  
  private Long carZeroIdealArrivalEpochMillis = null;
  
  private Long organizationId = null;
  


    public Builder id(Long id) {
      this.id = id;
      return this;
    }
    
    public Builder segmentNumber(Long segmentNumber) {
      this.segmentNumber = segmentNumber;
      return this;
    }

    public Builder segmentOffsetMillis(Long segmentOffsetMillis) {
      this.segmentOffsetMillis = segmentOffsetMillis;
      return this;
    }

    public Builder carZeroSegmentStartEpochMillis(Long carZeroSegmentStartEpochMillis) {
      this.carZeroSegmentStartEpochMillis = carZeroSegmentStartEpochMillis;
      return this;
    }

    public Builder carZeroIdealArrivalEpochMillis(Long carZeroIdealArrivalEpochMillis) {
      this.carZeroIdealArrivalEpochMillis = carZeroIdealArrivalEpochMillis;
      return this;
    }

    public Builder organizationId(Long organizationId) {
      this.organizationId = organizationId;
      return this;
    }

    /**
     * The build method creates and returns the immutable Entity object.
     */
    public abstract RouteTimingPointDTO build();
  }
}
