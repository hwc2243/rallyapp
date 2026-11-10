package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDTO;

public class CompetitorTelemetryDTO extends BaseCompetitorTelemetryDTO
{
  private static final long serialVersionUID = 1L;

  public CompetitorTelemetryDTO () {
  }
  
  public CompetitorTelemetryDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseCompetitorTelemetryDTO.Builder {
    public CompetitorTelemetryDTO build() {
      return new CompetitorTelemetryDTO(this);
    }
  }
}
