

class OrganizationMembershipDto {
  const OrganizationMembershipDto({
    this.id,
    this.serverId,
    this.role,
    this.organizationId,
    this.userId,
  });

  factory OrganizationMembershipDto.fromJson(Map<String, dynamic> json) => OrganizationMembershipDto(
    serverId: json['id'] as int?,
    role: json['role'] as String?,
    organizationId: json['organizationId'] as int?,
    userId: json['userId'] as int?,
  );

  final int? id;
  final int? serverId;
  final String? role;
  final int? organizationId;
  final int? userId;

  OrganizationMembershipDto forOrganizationId(int selectedOrganizationId) => OrganizationMembershipDto(
    id: id,
    serverId: serverId,
    role: role,
    organizationId: selectedOrganizationId,
    userId: userId,
  );


  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (role != null) 'role': role,
    if (organizationId != null) 'organizationId': organizationId,
    if (userId != null) 'userId': userId,
  };
}
