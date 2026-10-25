package com.rallyapp.rallymaster.spring;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** Registers request-scoped application context handling for MVC controllers. */
@Configuration
public class WebMvcConfiguration implements WebMvcConfigurer {

	private final ContextInterceptor contextInterceptor;

	public WebMvcConfiguration(ContextInterceptor contextInterceptor) {
		this.contextInterceptor = contextInterceptor;
	}

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		registry.addInterceptor(contextInterceptor);
	}
}
