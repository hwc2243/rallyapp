package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRouteDTO;

public class RouteDTO extends BaseRouteDTO
{
  private static final long serialVersionUID = 1L;

  public RouteDTO () {
  }
  
  public RouteDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRouteDTO.Builder {
    public RouteDTO build() {
      return new RouteDTO(this);
    }
  }
}
