package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRouteTimingPointPersistence<E extends RouteTimingPointEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public E findFirstByOrganizationIdAndRouteTimingPlanIdAndRouteItemId(Long organizationId, Long routeTimingPlanId, Long routeItemId);


}
