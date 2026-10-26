package com.rallyapp.rallymaster.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationRequest;
import org.springframework.security.web.SecurityFilterChain;

import com.rallyapp.rallymaster.keycloak.KeycloakLogoutHandler;

/** Browser login flow used with the local Keycloak realm. */
@Configuration
@Profile({"local", "production"})
public class LocalSecurityConfiguration {

	@Bean
	SecurityFilterChain localSecurityFilterChain(
			HttpSecurity http,
			OAuth2AuthorizationRequestResolver authorizationRequestResolver,
			KeycloakLogoutHandler keycloakLogoutHandler) throws Exception {
		return http
				.authorizeHttpRequests(authorize -> authorize
						.requestMatchers("/", "/signup", "/privacy", "/actuator/health").permitAll()
						.anyRequest().authenticated())
				.oauth2Login(oauth2 -> oauth2
						.authorizationEndpoint(endpoint -> endpoint.authorizationRequestResolver(authorizationRequestResolver)))
				.logout(logout -> logout
						.addLogoutHandler(keycloakLogoutHandler)
						.logoutSuccessUrl("/"))
				.build();
	}

	/**
	 * Adds Keycloak's registration action to the normal Spring OAuth request. This is
	 * important because Spring must generate and store the state and nonce values
	 * before Keycloak redirects to the callback.
	 */
	@Bean
	OAuth2AuthorizationRequestResolver authorizationRequestResolver(
			ClientRegistrationRepository clientRegistrationRepository) {
		DefaultOAuth2AuthorizationRequestResolver delegate =
				new DefaultOAuth2AuthorizationRequestResolver(clientRegistrationRepository, "/oauth2/authorization");

		return new OAuth2AuthorizationRequestResolver() {
			@Override
			public OAuth2AuthorizationRequest resolve(HttpServletRequest request) {
				return customize(delegate.resolve(request), request);
			}

			@Override
			public OAuth2AuthorizationRequest resolve(HttpServletRequest request, String clientRegistrationId) {
				return customize(delegate.resolve(request, clientRegistrationId), request);
			}

			private OAuth2AuthorizationRequest customize(
					OAuth2AuthorizationRequest authorizationRequest, HttpServletRequest request) {
				if (authorizationRequest == null || !"true".equals(request.getParameter("register"))) {
					return authorizationRequest;
				}

				return OAuth2AuthorizationRequest.from(authorizationRequest)
						.additionalParameters(parameters -> parameters.put("kc_action", "register"))
						.build();
			}
		};
	}
}
