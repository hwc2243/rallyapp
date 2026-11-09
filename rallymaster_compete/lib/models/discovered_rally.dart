class DiscoveredRally {
  const DiscoveredRally({
    required this.id,
    required this.name,
    required this.date,
  });

  factory DiscoveredRally.fromJson(Map<String, dynamic> json) =>
      DiscoveredRally(
        id: (json['rallyId'] as num).toInt(),
        name: json['name'] as String? ?? 'Unnamed rally',
        date: json['date'] as String? ?? '',
      );

  final int id;
  final String name;
  final String date;
}

class DiscoveredRoute {
  const DiscoveredRoute({required this.id, required this.name});

  factory DiscoveredRoute.fromJson(Map<String, dynamic> json) =>
      DiscoveredRoute(
        id: (json['routeId'] as num).toInt(),
        name: json['name'] as String? ?? 'Unnamed route',
      );

  final int id;
  final String name;
}
