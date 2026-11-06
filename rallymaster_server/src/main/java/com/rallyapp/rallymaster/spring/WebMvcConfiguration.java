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
		// OAuth's authorization and callback endpoints must not be redirected by
		// the application-context setup. Applying this interceptor to every
		// request can otherwise turn an authentication failure or callback into a
		// redirect loop.
		registry.addInterceptor(contextInterceptor)
				.addPathPatterns("/", "/home", "/rally/**", "/signin/**");
	}
}
