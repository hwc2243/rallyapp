package com.rallyapp.rallymaster.dto;

import com.rallyapp.rallymaster.dto.base.BaseOrganizationMembershipDTO;
import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;

public class OrganizationMembershipDTO extends BaseOrganizationMembershipDTO
{
  private static final long serialVersionUID = 1L;

  public OrganizationMembershipDTO () {
  }
  
  public OrganizationMembershipDTO (Builder builder) {
    super(builder);
  }
  
  public static class Builder extends BaseOrganizationMembershipDTO.Builder {
    public OrganizationMembershipDTO build() {
      return new OrganizationMembershipDTO(this);
    }
  }
}