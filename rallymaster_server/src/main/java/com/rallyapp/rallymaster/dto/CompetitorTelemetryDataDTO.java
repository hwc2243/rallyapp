package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDataDTO;

public class CompetitorTelemetryDataDTO extends BaseCompetitorTelemetryDataDTO
{
  private static final long serialVersionUID = 1L;

  public CompetitorTelemetryDataDTO () {
  }
  
  public CompetitorTelemetryDataDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseCompetitorTelemetryDataDTO.Builder {
    public CompetitorTelemetryDataDTO build() {
      return new CompetitorTelemetryDataDTO(this);
    }
  }
}
