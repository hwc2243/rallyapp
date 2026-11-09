package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/** Available in every profile because competition event passwords are data, not web security. */
@Configuration
public class CompetitionPasswordConfiguration {

  @Bean
  PasswordEncoder competitionEventPasswordEncoder() {
    return new BCryptPasswordEncoder();
  }
}
