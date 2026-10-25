package com.rallyapp.rallymaster.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

	@GetMapping({"/", "/home"})
	String home() {
		return "index";
	}

	@GetMapping("/signup")
	String signup() {
		return "redirect:/oauth2/authorization/keycloak?register=true";
	}
}
