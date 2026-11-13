

class RouteDto {
  const RouteDto({
    this.id,
    this.serverId,
    this.name,
    this.description,
    this.status,
    this.defaultSpeed,
    this.restartIntervalMillis,
    this.defaultPauseDurationMillis,
    this.timeZone,
    this.carZeroStartEpochMillis,
    this.maximumCheckpointScore,
    this.organizationId,
    this.rallyId,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) => RouteDto(
    serverId: json['id'] as int?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    status: json['status'] as String?,
    defaultSpeed: json['defaultSpeed'] as double?,
    restartIntervalMillis: json['restartIntervalMillis'] as int?,
    defaultPauseDurationMillis: json['defaultPauseDurationMillis'] as int?,
    timeZone: json['timeZone'] as String?,
    carZeroStartEpochMillis: json['carZeroStartEpochMillis'] as int?,
    maximumCheckpointScore: json['maximumCheckpointScore'] as int?,
    organizationId: json['organizationId'] as int?,
    rallyId: json['rallyId'] as int?,
  );

  final int? id;
  final int? serverId;
  final String? name;
  final String? description;
  final String? status;
  final double? defaultSpeed;
  final int? restartIntervalMillis;
  final int? defaultPauseDurationMillis;
  final String? timeZone;
  final int? carZeroStartEpochMillis;
  final int? maximumCheckpointScore;
  final int? organizationId;
  final int? rallyId;

  RouteDto forOrganizationId(int selectedOrganizationId) => RouteDto(
    id: id,
    serverId: serverId,
    name: name,
    description: description,
    status: status,
    defaultSpeed: defaultSpeed,
    restartIntervalMillis: restartIntervalMillis,
    defaultPauseDurationMillis: defaultPauseDurationMillis,
    timeZone: timeZone,
    carZeroStartEpochMillis: carZeroStartEpochMillis,
    maximumCheckpointScore: maximumCheckpointScore,
    organizationId: selectedOrganizationId,
    rallyId: rallyId,
  );


  Map<String, dynamic> toJson() => {
    if (serverId != null) 'id': serverId,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (status != null) 'status': status,
    if (defaultSpeed != null) 'defaultSpeed': defaultSpeed,
    if (restartIntervalMillis != null) 'restartIntervalMillis': restartIntervalMillis,
    if (defaultPauseDurationMillis != null) 'defaultPauseDurationMillis': defaultPauseDurationMillis,
    if (timeZone != null) 'timeZone': timeZone,
    if (carZeroStartEpochMillis != null) 'carZeroStartEpochMillis': carZeroStartEpochMillis,
    if (maximumCheckpointScore != null) 'maximumCheckpointScore': maximumCheckpointScore,
    if (organizationId != null) 'organizationId': organizationId,
    if (rallyId != null) 'rallyId': rallyId,
  };
}
