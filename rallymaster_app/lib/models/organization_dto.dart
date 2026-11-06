

class OrganizationDto {
  const OrganizationDto({
    this.id,
    this.serverId,
    this.name,
  });

  factory OrganizationDto.fromJson(Map<String, dynamic> json) => OrganizationDto(
    serverId: json['id'] as int?,
    name: json['name'] as String?,
  );

  final int? id;
  final int? serverId;
  final String? name;



  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (name != null) 'name': name,
  };
}
