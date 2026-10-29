import 'organization_dto.dart';
import 'organization_membership_dto.dart';
import 'rally_dto.dart';

class RallySetupSelection {
  const RallySetupSelection({
    required this.organization,
    required this.organizationMembership,
    required this.rally,
  });

  final OrganizationDto organization;
  final OrganizationMembershipDto organizationMembership;
  final RallyDto rally;
}
