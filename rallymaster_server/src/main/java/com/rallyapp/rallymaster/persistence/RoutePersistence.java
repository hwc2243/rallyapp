package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRoutePersistence;
import java.util.List;

public interface RoutePersistence extends BaseRoutePersistence<RouteEntity,Long>
{
	List<RouteEntity> findByRally_IdAndOrganizationId(
		Long rallyId, Long organizationId);
} 
