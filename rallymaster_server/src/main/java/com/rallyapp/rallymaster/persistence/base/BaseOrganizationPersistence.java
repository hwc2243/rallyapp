package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.OrganizationEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseOrganizationPersistence<E extends OrganizationEntity, ID> extends JpaRepository<E, ID>
{


    public E findFirstByName(String name);

}
