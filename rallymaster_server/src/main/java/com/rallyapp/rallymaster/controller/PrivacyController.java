package com.rallyapp.rallymaster.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/** Public privacy notice for RallyMaster services and companion applications. */
@Controller
public class PrivacyController {

	@GetMapping("/privacy")
	String privacy() {
		return "privacy";
	}
}
