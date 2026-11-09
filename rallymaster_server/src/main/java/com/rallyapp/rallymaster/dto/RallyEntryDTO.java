package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseRallyEntryDTO;

public class RallyEntryDTO extends BaseRallyEntryDTO
{
  private static final long serialVersionUID = 1L;

  public RallyEntryDTO () {
  }
  
  public RallyEntryDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseRallyEntryDTO.Builder {
    public RallyEntryDTO build() {
      return new RallyEntryDTO(this);
    }
  }
}
