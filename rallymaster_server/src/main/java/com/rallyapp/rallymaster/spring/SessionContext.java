package com.rallyapp.rallymaster.spring;

import com.rallyapp.rallymaster.dto.OrganizationDTO;
import com.rallyapp.rallymaster.dto.UserDTO;

public class SessionContext {

	private static final ThreadLocal<OrganizationDTO> ORGANIZATION_HOLDER = new ThreadLocal<>();

    private static final ThreadLocal<UserDTO> USER_HOLDER = new ThreadLocal<>();

    public static void setCurrentOrganization (OrganizationDTO organization) {
    	ORGANIZATION_HOLDER.set(organization);
    }
    
    public static OrganizationDTO getCurrentOrganization () {
    	return ORGANIZATION_HOLDER.get();
    }
    
    public static void setCurrentUser(UserDTO user) {
        USER_HOLDER.set(user);
    }

    public static UserDTO getCurrentUser() {
        return USER_HOLDER.get();
    }

    
    public static void clear() {
    	ORGANIZATION_HOLDER.remove();
        USER_HOLDER.remove();
    }
}
