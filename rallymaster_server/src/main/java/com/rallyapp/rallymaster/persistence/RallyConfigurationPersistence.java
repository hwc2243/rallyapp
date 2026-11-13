package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRallyConfigurationPersistence;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RallyConfigurationPersistence extends BaseRallyConfigurationPersistence<RallyConfigurationEntity,Long>
{
	RallyConfigurationEntity findFirstByRally_Id(Long rallyId);

	@Modifying
	@Query("delete from RallyConfiguration configuration where configuration.rally.id = :rallyId and configuration.organizationId = :organizationId")
	int deleteForRallyAndOrganization(@Param("rallyId") Long rallyId,
		@Param("organizationId") Long organizationId);
} 
