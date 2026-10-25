package com.rallyapp.rallymaster.service.base;

import com.rallyapp.rallymaster.model.base.Multitenant;
import com.rallyapp.rallymaster.service.TenantDiscriminator;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;

public abstract class MultitenantServiceImpl {

	@Autowired
	protected TenantDiscriminator tenantDiscriminator;
	
	public MultitenantServiceImpl() {
		// TODO Auto-generated constructor stub
	}

	protected boolean hasAccess (Multitenant bean) {
		if (bean == null) {
			return false;
		} else {
			return tenantDiscriminator.getOrganizationId().equals(bean.getOrganizationId());
		}
	}
	
	public <X extends Multitenant> List<X> filterByAccess(Collection<X> beans) {
		if (beans == null || beans.isEmpty()) {
			return List.of(); // Return an empty, immutable list
		}

		// Use Java Streams to filter the collection based on the hasAccess method
		return beans.stream()
			.filter(this::hasAccess)
			.collect(Collectors.toList());
	}
}
