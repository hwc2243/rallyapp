package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.model.RouteInstructionInstructionType;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRouteInstructionPersistence<E extends RouteInstructionEntity, ID> extends JpaRepository<E, ID>
{


    public List<E> findByRouteId(Long routeId);


}
