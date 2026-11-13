package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteStatus;
import com.rallyapp.rallymaster.persistence.base.BaseRoutePersistence;
import java.util.List;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RoutePersistence extends BaseRoutePersistence<RouteEntity,Long>
{
	List<RouteEntity> findByRally_IdAndOrganizationId(
		Long rallyId, Long organizationId);

	List<RouteEntity> findByRally_IdAndStatus(Long rallyId, RouteStatus status);

	List<RouteEntity> findByStatus(RouteStatus status);

	/** Direct deletion avoids polymorphic persistence-context retention for Route. */
	@Modifying
	@Query("delete from Route route where route.id = :routeId and route.organizationId = :organizationId")
	int deleteForOrganization(@Param("routeId") Long routeId,
		@Param("organizationId") Long organizationId);
} 
