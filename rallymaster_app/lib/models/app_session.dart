import 'organization_dto.dart';
import 'rally_dto.dart';
import 'user_dto.dart';

/// The authenticated user and organization selected for the current session.
/// This is memory-only; the refresh token is the only persisted credential.
class AppSession {
  const AppSession({
    required this.user,
    required this.organization,
    this.rally,
  });

  final UserDto user;
  final OrganizationDto organization;
  final RallyDto? rally;

  int get organizationId {
    final serverId = organization.serverId;
    if (serverId == null) {
      throw StateError('The selected organization has no server id.');
    }
    return serverId;
  }
}
