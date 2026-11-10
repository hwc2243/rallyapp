class CompetitionCheckpoint {
  const CompetitionCheckpoint({
    required this.id,
    required this.number,
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.distance,
    required this.notes,
  });

  factory CompetitionCheckpoint.fromJson(Map<String, dynamic> json) =>
      CompetitionCheckpoint(
        id: (json['checkpointId'] as num).toInt(),
        number: (json['checkpointNumber'] as num?)?.toInt(),
        type: json['checkpointType'] as String? ?? 'CHECKPOINT',
        name: json['name'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toInt(),
        distance: (json['distance'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  final int id;
  final int? number;
  final String type;
  final String? name;
  final double? latitude;
  final double? longitude;
  final int? heading;
  final double? distance;
  final String? notes;
}
