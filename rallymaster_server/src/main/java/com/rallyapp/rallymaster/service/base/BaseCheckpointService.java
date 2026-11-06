package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseCheckpointDTO;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import com.rallyapp.rallymaster.service.ServiceException;
import java.util.List;

public interface BaseCheckpointService<D extends BaseCheckpointDTO, ID> extends EntityService<D, ID> {

	public List<D> findByRouteId (Long routeId);
}
