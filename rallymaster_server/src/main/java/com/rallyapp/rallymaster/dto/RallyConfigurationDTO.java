package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRallyConfigurationDTO;

public class RallyConfigurationDTO extends BaseRallyConfigurationDTO
{
  private static final long serialVersionUID = 1L;

  public RallyConfigurationDTO () {
  }
  
  public RallyConfigurationDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRallyConfigurationDTO.Builder {
    public RallyConfigurationDTO build() {
      return new RallyConfigurationDTO(this);
    }
  }
}
