package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.CheckpointEntity;
import com.rallyapp.rallymaster.persistence.base.BaseCheckpointPersistence;
import java.util.List;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CheckpointPersistence extends BaseCheckpointPersistence<CheckpointEntity,Long>
{
	@Query("select checkpoint from Checkpoint checkpoint where checkpoint.route.id = :routeId")
	List<CheckpointEntity> findAllForRoute(@Param("routeId") Long routeId);

	@Query("select checkpoint from Checkpoint checkpoint "
		+ "where checkpoint.route.id = :routeId and checkpoint.checkpointType = :checkpointType")
	List<CheckpointEntity> findAllForRouteAndCheckpointType(
		@Param("routeId") Long routeId,
		@Param("checkpointType") CheckpointCheckpointType checkpointType);
} 
