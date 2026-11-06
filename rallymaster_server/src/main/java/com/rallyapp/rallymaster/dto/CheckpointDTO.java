package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseCheckpointDTO;

public class CheckpointDTO extends BaseCheckpointDTO
{
  private static final long serialVersionUID = 1L;

  public CheckpointDTO () {
  }
  
  public CheckpointDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseCheckpointDTO.Builder {
    public CheckpointDTO build() {
      return new CheckpointDTO(this);
    }
  }
}
