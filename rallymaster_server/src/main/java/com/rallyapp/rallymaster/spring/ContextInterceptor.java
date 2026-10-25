package com.rallyapp.rallymaster.spring;

import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.OrganizationMembershipService;
import com.rallyapp.rallymaster.service.OrganizationService;
import com.rallyapp.rallymaster.service.UserService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Component
public class ContextInterceptor implements HandlerInterceptor {

	private final Logger logger = LoggerFactory.getLogger(ContextInterceptor.class);
	
	public static final String ORGANIZATION_ID = "ORGANIZATION_ID";
	
	@Autowired
	protected OrganizationService organizationService;
	
	@Autowired
	protected OrganizationMembershipService organizationMembershipService;
	
	@Autowired
	protected UserService userService;
	
	public ContextInterceptor() {
		// TODO Auto-generated constructor stub
	}

	@Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // Get the authenticated user from the security context
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication.getPrincipal() instanceof DefaultOidcUser) {
			DefaultOidcUser oidcUser = (DefaultOidcUser)authentication.getPrincipal();
			
			String emailAddress = oidcUser.getEmail();
			
			logger.debug("ContextInterceptor: Looking for user : " + emailAddress);
			UserDTO user = userService.fetchByEmailAddress(emailAddress);
			if (user == null) {
				// Extract and log user details from the attributes map
	            Map<String, Object> attributes = oidcUser.getAttributes();
	            
	            logger.debug("Authenticated User Details:");
	            logger.debug("Username (email): " + emailAddress);
	            String firstName = (String) attributes.get("given_name");
	            logger.debug("First Name: " + firstName);
	            String lastName = (String)	attributes.get("family_name");
	            logger.debug("Last Name: " + lastName);
	            String registrationId = ((OAuth2AuthenticationToken)authentication).getAuthorizedClientRegistrationId();
	            logger.debug("Registration ID (provider): " + registrationId);
	            
	            if (user == null) {
	            	user = new UserDTO.Builder()
	            			.firstName(firstName)
	            			.lastName(lastName)
	            			.emailAddress(emailAddress)
	            			.build();
	            	
	            	user = userService.create(user);
	            	SessionContext.setCurrentUser(user);
	            	SessionContext.setCurrentOrganization(null);
	            
	            	logger.info("ContextInterceptor: New user created: " + user.getEmailAddress() + ", redirecting to onboarding page");
	            	response.sendRedirect("/signin/onboard");
	            	
				return false;
	            }
			} else {
				logger.debug("ContextInterceptor: Current user set to: " + user.getEmailAddress());
				SessionContext.setCurrentUser(user);
				if (request.getRequestURI().startsWith("/signin/")) {
					return true;
				}

				HttpSession session = request.getSession();
				Long organizationId = (Long)session.getAttribute(ORGANIZATION_ID);
				if (organizationId != null && organizationId != -1) {
					OrganizationDTO organization = organizationService.get(organizationId);
					if (organization != null) {
						SessionContext.setCurrentOrganization(organization);
						return true;
					}
					session.removeAttribute(ORGANIZATION_ID);
				}

				List<OrganizationDTO> organizations = organizationMembershipService.findOrganizationsByUser(user);
				if (organizations != null && organizations.size() == 1) {
					SessionContext.setCurrentOrganization(organizations.getFirst());
					session.setAttribute(ORGANIZATION_ID, organizations.getFirst().getId());
					return true;
				}
				if (organizations != null && organizations.size() > 1) {
					response.sendRedirect("/signin/select");
					return false;
				}
				if (!request.getRequestURI().equals("/home")) {
					response.sendRedirect("/home");
					return false;
				}
			}
        }
        return true;
    }
	
	@Override
	public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
			ModelAndView modelAndView) throws Exception {
		if (modelAndView != null) {
			modelAndView.addObject("currentOrganization", SessionContext.getCurrentOrganization());
			modelAndView.addObject("currentOrganizations", organizationMembershipService.findOrganizationsByUser(SessionContext.getCurrentUser()));
			modelAndView.addObject("currentUser", SessionContext.getCurrentUser());
		}
	}

	@Override
	public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler,
			Exception ex) throws Exception {
		SessionContext.clear();
	}
}
