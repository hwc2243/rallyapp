class RouteTimingPlanView {
  const RouteTimingPlanView({
    required this.version,
    required this.arrivals,
    required this.speeds,
  });

  factory RouteTimingPlanView.fromJson(Map<String, dynamic> json) =>
      RouteTimingPlanView(
        version: json['version'] as int?,
        arrivals: {
          for (final point in (json['points'] as List<dynamic>? ?? const []))
            (point as Map<String, dynamic>)['routeItemId'] as int:
                (point)['arrivalTime'] as String,
        },
        speeds: {
          for (final point in (json['points'] as List<dynamic>? ?? const []))
            (point as Map<String, dynamic>)['routeItemId'] as int:
                (point)['speed'] as num?,
        },
      );

  final int? version;
  final Map<int, String> arrivals;
  final Map<int, num?> speeds;
}
