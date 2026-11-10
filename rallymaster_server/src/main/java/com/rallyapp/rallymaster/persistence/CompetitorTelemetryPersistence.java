package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import com.rallyapp.rallymaster.persistence.base.BaseCompetitorTelemetryPersistence;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CompetitorTelemetryPersistence extends BaseCompetitorTelemetryPersistence<CompetitorTelemetryEntity,Long>
{
	boolean existsByOrganizationIdAndRallyEntry_Id(Long organizationId, Long rallyEntryId);

	@Query("select distinct telemetry from CompetitorTelemetry telemetry "
			+ "join fetch telemetry.checkpoint checkpoint "
			+ "left join fetch telemetry.data "
			+ "where telemetry.organizationId = :organizationId "
			+ "and telemetry.rallyEntry.id = :rallyEntryId "
			+ "and telemetry.route.id = :routeId "
			+ "order by telemetry.occurredAt")
	List<CompetitorTelemetryEntity> findForTelemetryView(
			@Param("organizationId") Long organizationId,
			@Param("rallyEntryId") Long rallyEntryId,
			@Param("routeId") Long routeId);
} 
