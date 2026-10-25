package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseOrganizationDTO;

public class OrganizationDTO extends BaseOrganizationDTO
{
  private static final long serialVersionUID = 1L;

  public OrganizationDTO () {
  }
  
  public OrganizationDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseOrganizationDTO.Builder {
    public OrganizationDTO build() {
      return new OrganizationDTO(this);
    }
  }
}