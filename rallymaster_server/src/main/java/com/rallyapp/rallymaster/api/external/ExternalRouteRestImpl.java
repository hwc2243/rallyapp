package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRouteRestImpl;

@RestController
@RequestMapping("/api/external/route")
public class ExternalRouteRestImpl
   extends BaseExternalRouteRestImpl
   implements ExternalRouteRest
{
}
