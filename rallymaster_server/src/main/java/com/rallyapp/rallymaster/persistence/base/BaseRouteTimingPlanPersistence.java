package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.model.RouteTimingPlanDistanceUnit;
import com.rallyapp.rallymaster.model.RouteTimingPlanScoringUnit;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRouteTimingPlanPersistence<E extends RouteTimingPlanEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public E findFirstByOrganizationIdAndRouteId(Long organizationId, Long routeId);


}
