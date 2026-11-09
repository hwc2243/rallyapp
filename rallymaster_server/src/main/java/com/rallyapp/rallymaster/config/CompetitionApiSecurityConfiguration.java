package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/** Security boundary for unauthenticated competitor onboarding. */
@Configuration
@Profile({"local", "keycloak", "production"})
public class CompetitionApiSecurityConfiguration {

  @Bean
  @Order(0)
  SecurityFilterChain competitionApiSecurityFilterChain(HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/compete", "/api/compete/**")
        .csrf(csrf -> csrf.disable())
        .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(authorize -> authorize
            .requestMatchers(HttpMethod.GET, "/api/compete/events/discover").permitAll()
            .requestMatchers(HttpMethod.GET, "/api/compete/events/*/routes").permitAll()
            .requestMatchers(HttpMethod.POST, "/api/compete/authenticate").permitAll()
            .requestMatchers(HttpMethod.POST, "/api/compete/registrations").permitAll()
            .anyRequest().denyAll())
        .build();
  }
}
