

class UserDto {
  const UserDto({
    this.id,
    this.serverId,
    this.emailAddress,
    this.firstName,
    this.lastName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    serverId: json['id'] as int?,
    emailAddress: json['emailAddress'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
  );

  final int? id;
  final int? serverId;
  final String? emailAddress;
  final String? firstName;
  final String? lastName;


  String get displayName => [
    firstName,
    lastName,
  ].whereType<String>().where((name) => name.isNotEmpty).join(' ');

  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
  };
}
