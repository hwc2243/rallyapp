class TimeAllowance {
  const TimeAllowance({
    required this.millis,
    required this.effectiveAfterRoutePosition,
  });

  factory TimeAllowance.fromJson(Map<String, dynamic> json) => TimeAllowance(
    millis: (json['millis'] as num).toInt(),
    effectiveAfterRoutePosition:
        (json['effectiveAfterRoutePosition'] as num?)?.toInt() ?? 0,
  );

  final int millis;
  final int effectiveAfterRoutePosition;

  Map<String, dynamic> toJson() => {
    'millis': millis,
    'effectiveAfterRoutePosition': effectiveAfterRoutePosition,
  };
}
