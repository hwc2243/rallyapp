package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseUserDTO;

public class UserDTO extends BaseUserDTO
{
  private static final long serialVersionUID = 1L;

  public UserDTO () {
  }
  
  public UserDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseUserDTO.Builder {
    public UserDTO build() {
      return new UserDTO(this);
    }
  }
}