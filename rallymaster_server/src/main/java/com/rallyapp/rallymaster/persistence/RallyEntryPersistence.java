package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRallyEntryPersistence;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RallyEntryPersistence extends BaseRallyEntryPersistence<RallyEntryEntity,Long>
{
	@Query("select entry from RallyEntry entry where entry.route.id = :routeId "
		+ "and entry.primaryDeviceId = :deviceId")
	RallyEntryEntity findFirstByRouteAndPrimaryDeviceId(
		@Param("routeId") Long routeId,
		@Param("deviceId") String deviceId);
} 
