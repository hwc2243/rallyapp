package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/** Local bootstrap configuration. Production must enable the keycloak profile. */
@Configuration
@Profile("!keycloak")
public class DevelopmentSecurityConfiguration {

	@Bean
	SecurityFilterChain developmentSecurityFilterChain(HttpSecurity http) throws Exception {
		return http
				.authorizeHttpRequests(authorize -> authorize.anyRequest().permitAll())
				.build();
	}
}
