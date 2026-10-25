class RallyDto {
  const RallyDto({
    this.id,
    required this.name,
    this.description,
    this.date,
    this.organizationId,
  });

  factory RallyDto.fromJson(Map<String, dynamic> json) => RallyDto(
    id: json['id'] as int?,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    date: json['date'] as String?,
    organizationId: json['organizationId'] as int?,
  );

  final int? id;
  final String name;
  final String? description;

  /// ISO-8601 calendar date (`yyyy-MM-dd`).
  final String? date;
  final int? organizationId;

  RallyDto forOrganization(int selectedOrganizationId) => RallyDto(
    id: id,
    name: name,
    description: description,
    date: date,
    organizationId: selectedOrganizationId,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (date != null) 'date': date,
    if (organizationId != null) 'organizationId': organizationId,
  };
}
