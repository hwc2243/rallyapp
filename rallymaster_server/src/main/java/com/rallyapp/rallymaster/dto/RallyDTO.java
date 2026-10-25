package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRallyDTO;

public class RallyDTO extends BaseRallyDTO
{
  private static final long serialVersionUID = 1L;

  public RallyDTO () {
  }
  
  public RallyDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRallyDTO.Builder {
    public RallyDTO build() {
      return new RallyDTO(this);
    }
  }
}