package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRouteInstructionDTO;

public class RouteInstructionDTO extends BaseRouteInstructionDTO
{
  private static final long serialVersionUID = 1L;

  public RouteInstructionDTO () {
  }
  
  public RouteInstructionDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRouteInstructionDTO.Builder {
    public RouteInstructionDTO build() {
      return new RouteInstructionDTO(this);
    }
  }
}
