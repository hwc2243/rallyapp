package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.api.external.base.BaseExternalCheckpointRestImpl;

@RestController
@RequestMapping("/api/external/checkpoint")
public class ExternalCheckpointRestImpl
   extends BaseExternalCheckpointRestImpl
   implements ExternalCheckpointRest
{
}
