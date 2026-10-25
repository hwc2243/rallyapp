class OrganizationDto {
  const OrganizationDto({required this.id, required this.name});

  factory OrganizationDto.fromJson(Map<String, dynamic> json) =>
      OrganizationDto(
        id: json['id'] as int?,
        name: json['name'] as String? ?? 'Unnamed organization',
      );

  final int? id;
  final String name;
}
