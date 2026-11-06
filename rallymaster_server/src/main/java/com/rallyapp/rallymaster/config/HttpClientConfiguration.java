package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/** HTTP client used for Keycloak back-channel logout. */
@Configuration
public class HttpClientConfiguration {

	@Bean
	RestTemplate restTemplate() {
		return new RestTemplate();
	}
}
