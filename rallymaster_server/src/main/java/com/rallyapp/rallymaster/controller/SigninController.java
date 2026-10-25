package com.rallyapp.rallymaster.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;
import com.rallyapp.rallymaster.service.OrganizationMembershipService;
import com.rallyapp.rallymaster.service.OrganizationService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.ContextInterceptor;
import com.rallyapp.rallymaster.spring.SessionContext;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/signin")
public class SigninController {
	
	@Autowired
	protected OrganizationMembershipService organizationMembershipService;

	@Autowired
	protected OrganizationService organizationService;

	@GetMapping("/select")
	public String select (ModelMap model) {
		model.put("organizations", organizationMembershipService.findOrganizationsByUser(SessionContext.getCurrentUser()));
		
		return "/signin/select.html";
		
	}
	
	@GetMapping("/onboard")
	public String onboard (ModelMap model) {
		model.put("organization", new OrganizationDTO());
		
		return "signin/onboard";
	}

	@PostMapping("/onboard")
	public String createOrganization(
			@ModelAttribute("organization") OrganizationDTO organization,
			@RequestParam(value = "name", required = false) String name,
			ModelMap model,
			HttpSession session) throws ServiceException {
		UserDTO user = SessionContext.getCurrentUser();
		String organizationName = name == null ? null : name.trim();

		if (user == null || user.getId() == null) {
			return "redirect:/";
		}
		if (organizationName == null || organizationName.isEmpty()) {
			model.put("organization", organization);
			model.put("organizationNameError", "Organization name is required.");
			return "signin/onboard";
		}

		OrganizationDTO createdOrganization = organizationService.createOrganizationFor(
				user, new OrganizationDTO.Builder().name(organizationName).build());

		SessionContext.setCurrentUser(user);
		SessionContext.setCurrentOrganization(createdOrganization);
		session.setAttribute(ContextInterceptor.ORGANIZATION_ID, createdOrganization.getId());

		return "redirect:/rally";
	}

	@PostMapping("/organization")
	public String selectOrganization(@RequestParam Long organizationId, HttpSession session) {
		UserDTO user = SessionContext.getCurrentUser();
		OrganizationDTO organization = organizationMembershipService.findOrganizationsByUser(user).stream()
				.filter(candidate -> candidate.getId().equals(organizationId))
				.findFirst()
				.orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Organization access denied."));

		SessionContext.setCurrentOrganization(organization);
		session.setAttribute(ContextInterceptor.ORGANIZATION_ID, organization.getId());
		return "redirect:/rally/list";
	}
}
