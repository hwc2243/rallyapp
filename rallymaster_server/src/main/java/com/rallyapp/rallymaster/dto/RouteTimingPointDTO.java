package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRouteTimingPointDTO;

public class RouteTimingPointDTO extends BaseRouteTimingPointDTO
{
  private static final long serialVersionUID = 1L;

  public RouteTimingPointDTO () {
  }
  
  public RouteTimingPointDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRouteTimingPointDTO.Builder {
    public RouteTimingPointDTO build() {
      return new RouteTimingPointDTO(this);
    }
  }
}
