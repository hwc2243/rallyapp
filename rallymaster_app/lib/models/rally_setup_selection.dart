import 'organization_dto.dart';
import 'rally_dto.dart';

class RallySetupSelection {
  const RallySetupSelection({required this.organization, required this.rally});

  final OrganizationDto organization;
  final RallyDto rally;
}
