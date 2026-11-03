package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseCheckpointPersistence<E extends CheckpointEntity, ID> extends JpaRepository<E, ID>
{


    public List<E> findByRouteId(Long routeId);


}
