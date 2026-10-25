package com.rallyapp.rallymaster.persistence.base;




import com.rallyapp.rallymaster.entity.UserEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseUserPersistence<E extends UserEntity, ID> extends JpaRepository<E, ID>
{


    public E findFirstByEmailAddress(String emailAddress);

}
