package com.rallyapp.rallymaster.model;

import com.rallyapp.rallymaster.model.base.BaseCompetitorTelemetry;
import com.rallyapp.rallymaster.model.Checkpoint;
import com.rallyapp.rallymaster.model.CompetitorTelemetryData;
import com.rallyapp.rallymaster.model.RallyEntry;
import com.rallyapp.rallymaster.model.Route;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface CompetitorTelemetry<RALLYENTRY, ROUTE, CHECKPOINT, COMPETITORTELEMETRYDATA> extends BaseCompetitorTelemetry<RALLYENTRY, ROUTE, CHECKPOINT, COMPETITORTELEMETRYDATA>
{ 
}
