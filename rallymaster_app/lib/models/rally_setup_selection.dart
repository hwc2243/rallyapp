import 'organization_dto.dart';
import 'organization_membership_dto.dart';
import 'rally_dto.dart';
import 'route_dto.dart';
import 'route_item_dto.dart';

class RallySetupSelection {
  const RallySetupSelection({
    required this.organization,
    required this.organizationMembership,
    required this.rally,
    required this.route,
    required this.routeItems,
  });

  final OrganizationDto organization;
  final OrganizationMembershipDto organizationMembership;
  final RallyDto rally;
  final RouteDto route;
  final List<RouteItemDto> routeItems;
}
