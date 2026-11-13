

class CheckpointDto {
  const CheckpointDto({
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
    this.checkpointNumber,
    this.checkpointType,
    this.name,
    this.routeId,
  });

  factory CheckpointDto.fromJson(Map<String, dynamic> json) => CheckpointDto(
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
    checkpointNumber: json['checkpointNumber'] as int?,
    checkpointType: json['checkpointType'] as String?,
    name: json['name'] as String?,
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
  final int? checkpointNumber;
  final String? checkpointType;
  final String? name;
  final int? routeId;

  CheckpointDto forOrganizationId(int selectedOrganizationId) => CheckpointDto(
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
    checkpointNumber: checkpointNumber,
    checkpointType: checkpointType,
    name: name,
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
    if (checkpointNumber != null) 'checkpointNumber': checkpointNumber,
    if (checkpointType != null) 'checkpointType': checkpointType,
    if (name != null) 'name': name,
    if (routeId != null) 'routeId': routeId,
  };
}
