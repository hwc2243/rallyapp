import 'checkpoint_dto.dart';
import 'organization_dto.dart';
import 'organization_membership_dto.dart';
import 'rally_dto.dart';
import 'route_dto.dart';
import 'route_item_dto.dart';
import 'user_dto.dart';

/// The authenticated user and organization selected for the current session.
/// This is memory-only; the refresh token is the only persisted credential.
class AppSession {
  AppSession({
    required this.user,
    required this.organization,
    required this.organizationMembership,
    this.rally,
    this.route,
    List<RouteItemDto>? routeItems,
    List<CheckpointDto>? checkpointDrafts,
  }) : routeItems = List.of(routeItems ?? const []),
       checkpointDrafts = List.of(checkpointDrafts ?? const []);

  final UserDto user;
  final OrganizationDto organization;
  final OrganizationMembershipDto organizationMembership;
  final RallyDto? rally;
  final RouteDto? route;
  final List<RouteItemDto> routeItems;

  /// Checkpoints added while planning that have not been saved to the server.
  final List<CheckpointDto> checkpointDrafts;

  int get organizationId {
    final serverId = organization.serverId;
    if (serverId == null) {
      throw StateError('The selected organization has no server id.');
    }
    return serverId;
  }
}
