package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseCompetitorTelemetryDataDTO;
import com.rallyapp.rallymaster.service.ServiceException;
import java.time.LocalDateTime;
import java.util.List;

public interface BaseCompetitorTelemetryDataService<D extends BaseCompetitorTelemetryDataDTO, ID> extends EntityService<D, ID> {
	public List<D> findByCompetitorTelemetryId (Long competitorTelemetryId);
}
