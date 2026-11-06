import 'base/base_organization_membership_provider.dart';
import '../models/organization_membership_dto.dart';

/// Application extension point for OrganizationMembership API operations.
///
/// This file is generated only when it does not already exist and is preserved
/// on subsequent service builds.
class OrganizationMembershipProvider
    extends BaseOrganizationMembershipProvider {
  OrganizationMembershipProvider({
    required super.httpClient,
    required super.tenantProvider,
  });

  /// Returns the current user's membership in the selected organization.
  ///
  /// The server returns 404 when the user has no membership for this context;
  /// callers receive `null` for that expected absence.
  Future<OrganizationMembershipDto?> me() => execute(() async {
    final response = await httpClient.get(
      '$resourcePath/me',
      headers: requestHeaders,
    );
    if (response.statusCode == 404) {
      clear();
      return null;
    }
    httpClient.ensureSuccess(response);
    final membership = OrganizationMembershipDto.fromJson(
      decodeObject(response),
    );
    replaceAll([membership]);
    return membership;
  });
}
