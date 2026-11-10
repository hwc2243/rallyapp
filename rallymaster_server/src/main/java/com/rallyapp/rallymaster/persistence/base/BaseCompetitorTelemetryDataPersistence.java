package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.CompetitorTelemetryDataEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseCompetitorTelemetryDataPersistence<E extends CompetitorTelemetryDataEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public List<E> findByOrganizationIdAndCompetitorTelemetry_Id(Long organizationId, Long competitorTelemetryId);
}
