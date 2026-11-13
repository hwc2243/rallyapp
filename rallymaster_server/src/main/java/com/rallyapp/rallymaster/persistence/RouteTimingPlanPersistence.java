package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteTimingPlanEntity;
import com.rallyapp.rallymaster.persistence.base.BaseRouteTimingPlanPersistence;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RouteTimingPlanPersistence extends BaseRouteTimingPlanPersistence<RouteTimingPlanEntity,Long>
{
  /** Bulk delete deliberately bypasses the generated cascade back to Route. */
  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query("delete from RouteTimingPlan plan where plan.id = :planId")
  int deleteForId(@Param("planId") Long planId);
} 
