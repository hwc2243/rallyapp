package com.rallyapp.rallymaster.api.external;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;

import com.rallyapp.rallymaster.api.external.base.BaseExternalRallyRestImpl;
import com.rallyapp.rallymaster.dto.RouteDTO;
import com.rallyapp.rallymaster.service.RouteService;
import java.util.List;

@RestController
@RequestMapping("/api/external/rally")
public class ExternalRallyRestImpl
   extends BaseExternalRallyRestImpl
   implements ExternalRallyRest
{
	
}
