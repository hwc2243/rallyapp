package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RallyEntryEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRallyEntryPersistence<E extends RallyEntryEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public E findFirstByOrganizationIdAndRallyIdAndCarNumber(Long organizationId, Long rallyId, Long carNumber);


    public E findFirstByOrganizationIdAndRallyIdAndPrimaryDeviceId(Long organizationId, Long rallyId, String primaryDeviceId);


    public List<E> findByOrganizationIdAndRoute_Id(Long organizationId, Long routeId);
}
