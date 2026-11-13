package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPlanDTO;

public class RouteTimingPlanDTO extends BaseRouteTimingPlanDTO
{
  private static final long serialVersionUID = 1L;

  public RouteTimingPlanDTO () {
  }
  
  public RouteTimingPlanDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRouteTimingPlanDTO.Builder {
    public RouteTimingPlanDTO build() {
      return new RouteTimingPlanDTO(this);
    }
  }
}
