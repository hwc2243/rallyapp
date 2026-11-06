package com.rallyapp.rallymaster.spring;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.filter.OncePerRequestFilter;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.OrganizationMembershipService;
import com.rallyapp.rallymaster.service.OrganizationService;
import com.rallyapp.rallymaster.service.UserService;

import java.io.IOException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Filter that runs after authentication to extract required context (User ID
 * and Organization ID header) and store it in UserContext.
 */
public class RestContextFilter extends OncePerRequestFilter {

        private final Logger logger = LoggerFactory.getLogger(RestContextFilter.class);

        private static final String ORGANIZATION_HEADER = "organizationId";

        @Autowired
        protected OrganizationService organizationService;
        
        @Autowired
        protected OrganizationMembershipService organizationMembershipService;

        @Autowired
        protected UserService userService;

        public RestContextFilter() {
        }

        @Override
        protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
                        throws ServletException, IOException {

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

                if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {

                        String userId = jwt.getSubject();
                        String userEmail = jwt.getClaimAsString("email");
                        logger.debug("RestContextFilter: Authenticated user: " + userEmail);

                        try {
                                UserDTO user = userService.fetchByEmailAddress(userEmail);
                                if (user == null) {
                                        logger.warn("RestContextFilter: No user found for email: " + userEmail);
                                        filterChain.doFilter(request, response);
                                        return;
                                }
                                SessionContext.setCurrentUser(user);

                                String organizationIdText = request.getHeader(ORGANIZATION_HEADER);
                                if (organizationIdText != null && !organizationIdText.isEmpty() && !organizationIdText.equals("null")) {
                                        logger.debug("RestContextFilter: Organization ID from header: " + organizationIdText);
                                        Long organizationId = Long.parseLong(organizationIdText);
                                        OrganizationDTO organization = organizationService.get(organizationId);
                                        if (organization == null) {
                                                logger.warn("RestContextFilter: No organization found for ID: " + organizationId);
                                                filterChain.doFilter(request, response);
                                                return;
                                        }
                                        
                                        List<OrganizationDTO> organizations = organizationMembershipService.findOrganizationsByUser(user);
                                        if (!organizations.contains(organization)) {
                                                logger.warn("RestContextFilter: User " + userEmail + " does not belong to organization ID: "
                                                                + organizationId);
                                                filterChain.doFilter(request, response);
                                                return;
                                        }
                                        
                                        SessionContext.setCurrentOrganization(organization);

                                } else {
                                        logger.warn("RestContextFilter: Missing organization_id header in request.");
                                }
                                filterChain.doFilter(request, response);
                        } catch (Exception ex) {
                                ex.printStackTrace();
                                logger.error("RestContextFilter: Exception occurred while setting context: " + ex.getMessage());
                        } finally {
                                SessionContext.clear();
                        }

                } else {
                        // No authentication or wrong principal type, just continue the chain
                        filterChain.doFilter(request, response);
                }
        }
}

