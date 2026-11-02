package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRouteItemDTO;

public class RouteItemDTO extends BaseRouteItemDTO
{
  private static final long serialVersionUID = 1L;

  public RouteItemDTO () {
  }
  
  public RouteItemDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRouteItemDTO.Builder {
    public RouteItemDTO build() {
      return new RouteItemDTO(this);
    }
  }
}
