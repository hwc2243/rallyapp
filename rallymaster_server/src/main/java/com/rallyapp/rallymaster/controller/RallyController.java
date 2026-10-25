package com.rallyapp.rallymaster.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.rallyapp.rallymaster.dto.RallyDTO;
import com.rallyapp.rallymaster.service.RallyService;
import com.rallyapp.rallymaster.service.ServiceException;
import com.rallyapp.rallymaster.spring.SessionContext;

@Controller
@RequestMapping("/rally")
public class RallyController {
	
	@Autowired
	protected RallyService rallyService;

	@GetMapping({"", "/", "/list", "/list.html"})
	public String list (ModelMap model) throws ServiceException {
		model.put("rallys", rallyService.findAll());
		
		return "rally/list";
		
	}

	@GetMapping("/new")
	public String newRally(ModelMap model) {
		model.put("rally", new RallyDTO());
		return "rally/form";
	}

	@PostMapping
	public String create(@ModelAttribute("rally") RallyDTO rally, BindingResult bindingResult) throws ServiceException {
		if (rally.getName() == null || rally.getName().isBlank()) {
			bindingResult.rejectValue("name", "required", "A rally name is required.");
		} else {
			rally.setName(rally.getName().trim());
		}
		if (rally.getDate() == null) {
			bindingResult.rejectValue("date", "required", "A rally date is required.");
		}

		if (bindingResult.hasErrors()) {
			return "rally/form";
		}

		if (SessionContext.getCurrentOrganization() == null) {
			return "redirect:/home";
		}

		// Always derive the tenant from the authenticated request, never the submitted form.
		rally.setOrganizationId(SessionContext.getCurrentOrganization().getId());
		rallyService.create(rally);
		return "redirect:/rally/list";
	}
}
