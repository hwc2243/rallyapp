package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.RallyEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRallyPersistence<E extends RallyEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);

}
