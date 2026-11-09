package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RallyConfigurationEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRallyConfigurationPersistence;

public interface RallyConfigurationPersistence extends BaseRallyConfigurationPersistence<RallyConfigurationEntity,Long>
{
	RallyConfigurationEntity findFirstByRally_Id(Long rallyId);
} 
