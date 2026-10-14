package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/** Enables Keycloak JWT bearer-token validation when the keycloak profile is active. */
@Configuration
@Profile("keycloak")
public class KeycloakSecurityConfiguration {

	@Bean
	SecurityFilterChain apiSecurityFilterChain(HttpSecurity http) throws Exception {
		return http
				.authorizeHttpRequests(authorize -> authorize
						.requestMatchers("/actuator/health").permitAll()
						.requestMatchers("/api/**").authenticated()
						.anyRequest().permitAll())
				.oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
				.build();
	}
}
