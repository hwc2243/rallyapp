package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRestImpl;

@RestController
@RequestMapping("/api/external/rally")
public class ExternalRallyRestImpl
   extends BaseExternalRallyRestImpl
   implements ExternalRallyRest
{
}