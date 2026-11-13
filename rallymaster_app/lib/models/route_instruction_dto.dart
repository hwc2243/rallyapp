

class RouteInstructionDto {
  const RouteInstructionDto({
    this.id,
    this.serverId,
    this.itemType,
    this.position,
    this.latitude,
    this.longitude,
    this.heading,
    this.distance,
    this.notes,
    this.deleted,
    this.organizationId,
    this.instructionNumber,
    this.instructionText,
    this.instructionType,
    this.speed,
    this.pauseDurationMillis,
    this.transitDurationMillis,
    this.routeId,
  });

  factory RouteInstructionDto.fromJson(Map<String, dynamic> json) => RouteInstructionDto(
    serverId: json['id'] as int?,
    itemType: json['itemType'] as String?,
    position: json['position'] as int?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    heading: json['heading'] as int?,
    distance: json['distance'] as double?,
    notes: json['notes'] as String?,
    deleted: json['deleted'] as bool?,
    organizationId: json['organizationId'] as int?,
    instructionNumber: json['instructionNumber'] as int?,
    instructionText: json['instructionText'] as String?,
    instructionType: json['instructionType'] as String?,
    speed: json['speed'] as double?,
    pauseDurationMillis: json['pauseDurationMillis'] as int?,
    transitDurationMillis: json['transitDurationMillis'] as int?,
    routeId: json['routeId'] as int?,
  );

  final int? id;
  final int? serverId;
  final String? itemType;
  final int? position;
  final double? latitude;
  final double? longitude;
  final int? heading;
  final double? distance;
  final String? notes;
  final bool? deleted;
  final int? organizationId;
  final int? instructionNumber;
  final String? instructionText;
  final String? instructionType;
  final double? speed;
  final int? pauseDurationMillis;
  final int? transitDurationMillis;
  final int? routeId;

  RouteInstructionDto forOrganizationId(int selectedOrganizationId) => RouteInstructionDto(
    id: id,
    serverId: serverId,
    itemType: itemType,
    position: position,
    latitude: latitude,
    longitude: longitude,
    heading: heading,
    distance: distance,
    notes: notes,
    deleted: deleted,
    instructionNumber: instructionNumber,
    instructionText: instructionText,
    instructionType: instructionType,
    speed: speed,
    pauseDurationMillis: pauseDurationMillis,
    transitDurationMillis: transitDurationMillis,
    organizationId: selectedOrganizationId,
    routeId: routeId,
  );


  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (itemType != null) 'itemType': itemType,
    if (position != null) 'position': position,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (heading != null) 'heading': heading,
    if (distance != null) 'distance': distance,
    if (notes != null) 'notes': notes,
    if (deleted != null) 'deleted': deleted,
    if (organizationId != null) 'organizationId': organizationId,
    if (instructionNumber != null) 'instructionNumber': instructionNumber,
    if (instructionText != null) 'instructionText': instructionText,
    if (instructionType != null) 'instructionType': instructionType,
    if (speed != null) 'speed': speed,
    if (pauseDurationMillis != null) 'pauseDurationMillis': pauseDurationMillis,
    if (transitDurationMillis != null) 'transitDurationMillis': transitDurationMillis,
    if (routeId != null) 'routeId': routeId,
  };
}
