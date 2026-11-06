package com.rallyapp.rallymaster.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.rallyapp.rallymaster.service.TenantDiscriminator;
import com.rallyapp.rallymaster.spring.SessionContext;

@Configuration
public class MultitenantConfig {

        public MultitenantConfig() {
                // TODO Auto-generated constructor stub
        }
        
        @Bean
        public TenantDiscriminator tenantDiscriminator() {
                return new TenantDiscriminator() {
                        public Long getOrganizationId () {
                                return (SessionContext.getCurrentOrganization() == null ? null : SessionContext.getCurrentOrganization().getId());
                        }
                };
        }

}