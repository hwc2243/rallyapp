package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalOrganizationMembershipRestImpl;

@RestController
@RequestMapping("/api/external/organizationMembership")
public class ExternalOrganizationMembershipRestImpl
   extends BaseExternalOrganizationMembershipRestImpl
   implements ExternalOrganizationMembershipRest
{
}