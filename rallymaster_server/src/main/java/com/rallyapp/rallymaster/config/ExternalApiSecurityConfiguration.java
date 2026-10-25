package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;

import com.rallyapp.rallymaster.spring.RestContextFilter;

/**
 * Bearer-token security for the mobile/external API. This chain is deliberately
 * separate from the browser login chain so REST requests are stateless and are
 * never redirected to an HTML login page.
 */
@Configuration
@Profile({"local", "keycloak", "production"})
public class ExternalApiSecurityConfiguration {

	@Bean
	RestContextFilter restContextFilter() {
		return new RestContextFilter();
	}

	@Bean
	@Order(1)
	SecurityFilterChain externalApiSecurityFilterChain(
			HttpSecurity http, RestContextFilter restContextFilter) throws Exception {
		return http
				.securityMatcher("/api/external", "/api/external/**")
				.csrf(csrf -> csrf.disable())
				.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
				.authorizeHttpRequests(authorize -> authorize.anyRequest().authenticated())
				.oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
				.addFilterAfter(restContextFilter, BearerTokenAuthenticationFilter.class)
				.build();
	}
}
