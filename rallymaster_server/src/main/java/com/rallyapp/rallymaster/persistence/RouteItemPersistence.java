package com.rallyapp.rallymaster.persistence;

import com.rallyapp.rallymaster.entity.RouteItemEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Cleanup operations for the abstract root of the joined route-item
 * hierarchy. Servicebuilder intentionally does not generate a repository for
 * abstract entities, but route deletion must remove these root rows after its
 * concrete NRI/checkpoint rows have been removed.
 */
public interface RouteItemPersistence extends JpaRepository<RouteItemEntity, Long> {

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query(value = "delete from route_instruction where id in "
      + "(select id from route_item where route_id = :routeId)", nativeQuery = true)
  int deleteInstructionsForRoute(@Param("routeId") Long routeId);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query(value = "delete from checkpoint where id in "
      + "(select id from route_item where route_id = :routeId)", nativeQuery = true)
  int deleteCheckpointsForRoute(@Param("routeId") Long routeId);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query(value = "delete from route_item where route_id = :routeId", nativeQuery = true)
  int deleteForRoute(@Param("routeId") Long routeId);
}
