package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteInstructionEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRouteInstructionPersistence;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RouteInstructionPersistence extends BaseRouteInstructionPersistence<RouteInstructionEntity,Long>
{
	@Query("select instruction from RouteInstruction instruction where instruction.route.id = :routeId")
	List<RouteInstructionEntity> findAllForRoute(@Param("routeId") Long routeId);
} 
