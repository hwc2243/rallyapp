class UserDto {
  const UserDto({
    required this.id,
    required this.emailAddress,
    required this.firstName,
    required this.lastName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as int?,
    emailAddress: json['emailAddress'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
  );

  final int? id;
  final String? emailAddress;
  final String? firstName;
  final String? lastName;

  String get displayName => [
    firstName,
    lastName,
  ].whereType<String>().where((name) => name.isNotEmpty).join(' ');
}
