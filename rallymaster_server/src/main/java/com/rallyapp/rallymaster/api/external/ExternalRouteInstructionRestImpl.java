package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteInstructionRestImpl;

@RestController
@RequestMapping("/api/external/routeInstruction")
public class ExternalRouteInstructionRestImpl
   extends BaseExternalRouteInstructionRestImpl
   implements ExternalRouteInstructionRest
{
}
