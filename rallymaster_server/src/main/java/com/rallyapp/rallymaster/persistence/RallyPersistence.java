package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RallyEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRallyPersistence;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RallyPersistence extends BaseRallyPersistence<RallyEntity,Long>
{
	@Modifying
	@Query("delete from Rally rally where rally.id = :rallyId and rally.organizationId = :organizationId")
	int deleteForOrganization(@Param("rallyId") Long rallyId,
		@Param("organizationId") Long organizationId);
} 
