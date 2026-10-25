package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.OrganizationMembershipEntity;
import com.rallyapp.rallymaster.model.OrganizationMembershipRole;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseOrganizationMembershipPersistence<E extends OrganizationMembershipEntity, ID> extends JpaRepository<E, ID>
{
    public List<E> findByOrganizationId(Long organizationId);


    public List<E> findByUserId(Long userId);

}
