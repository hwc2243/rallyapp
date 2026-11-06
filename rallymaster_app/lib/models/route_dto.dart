

class RouteDto {
  const RouteDto({
    this.id,
    this.serverId,
    this.name,
    this.description,
    this.organizationId,
    this.rallyId,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) => RouteDto(
    serverId: json['id'] as int?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    organizationId: json['organizationId'] as int?,
    rallyId: json['rallyId'] as int?,
  );

  final int? id;
  final int? serverId;
  final String? name;
  final String? description;
  final int? organizationId;
  final int? rallyId;

  RouteDto forOrganizationId(int selectedOrganizationId) => RouteDto(
    id: id,
    serverId: serverId,
    name: name,
    description: description,
    organizationId: selectedOrganizationId,
    rallyId: rallyId,
  );


  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (organizationId != null) 'organizationId': organizationId,
    if (rallyId != null) 'rallyId': rallyId,
  };
}
