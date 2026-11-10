package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDTO;
import com.rallyapp.rallymaster.dto.CompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

public interface BaseCompetitorTelemetryService<D extends BaseCompetitorTelemetryDTO, ID> extends EntityService<D, ID> {

	public D fetchByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt (Long rallyEntryId, Long checkpointId, java.time.LocalDateTime occurredAt);
	public List<D> findByRouteId (Long routeId);
	public Collection<CompetitorTelemetryDataDTO> getData (ID id) throws ServiceException;
}
