

class RallyDto {
  const RallyDto({
    this.id,
    this.serverId,
    this.name,
    this.description,
    this.date,
    this.organizationId,
    this.userId,
  });

  factory RallyDto.fromJson(Map<String, dynamic> json) => RallyDto(
    serverId: json['id'] as int?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    date: json['date'] as String?,
    organizationId: json['organizationId'] as int?,
    userId: json['userId'] as int?,
  );

  final int? id;
  final int? serverId;
  final String? name;
  final String? description;
  /// ISO-8601 calendar date (`yyyy-MM-dd`).
  final String? date;
  final int? organizationId;
  final int? userId;

  RallyDto forOrganizationId(int selectedOrganizationId) => RallyDto(
    id: id,
    serverId: serverId,
    name: name,
    description: description,
    date: date,
    organizationId: selectedOrganizationId,
    userId: userId,
  );


  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (date != null) 'date': date,
    if (organizationId != null) 'organizationId': organizationId,
    if (userId != null) 'userId': userId,
  };
}
