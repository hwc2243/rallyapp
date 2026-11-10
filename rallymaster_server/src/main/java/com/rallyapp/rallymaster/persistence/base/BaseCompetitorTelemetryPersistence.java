package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.CompetitorTelemetryEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseCompetitorTelemetryPersistence<E extends CompetitorTelemetryEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public E findFirstByOrganizationIdAndRallyEntryIdAndCheckpointIdAndOccurredAt(Long organizationId, Long rallyEntryId, Long checkpointId, java.time.LocalDateTime occurredAt);


    public List<E> findByOrganizationIdAndRoute_Id(Long organizationId, Long routeId);
}
