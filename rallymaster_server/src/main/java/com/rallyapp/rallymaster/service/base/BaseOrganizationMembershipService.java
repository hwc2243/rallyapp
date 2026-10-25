package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseOrganizationMembershipDTO;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import java.util.List;

public interface BaseOrganizationMembershipService<D extends BaseOrganizationMembershipDTO, ID> extends EntityService<D, ID> {

	public List<D> findByUserId (Long userId);
}
