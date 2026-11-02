package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RouteEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRoutePersistence<E extends RouteEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);

}
