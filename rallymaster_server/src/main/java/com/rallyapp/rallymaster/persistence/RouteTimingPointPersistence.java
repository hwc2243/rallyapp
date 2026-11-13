package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteTimingPointEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRouteTimingPointPersistence;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RouteTimingPointPersistence extends BaseRouteTimingPointPersistence<RouteTimingPointEntity,Long>
{
  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query("delete from RouteTimingPoint point where point.routeTimingPlan.id = :planId")
  int deleteForTimingPlan(@Param("planId") Long planId);
} 
