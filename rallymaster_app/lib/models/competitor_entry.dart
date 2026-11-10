/// A rallymaster-facing summary of a team registered for a route.
class CompetitorEntry {
  const CompetitorEntry({
    required this.entryId,
    required this.carNumber,
    required this.driverFirstName,
    required this.driverLastName,
    required this.navigatorFirstName,
    required this.navigatorLastName,
  });

  factory CompetitorEntry.fromJson(Map<String, dynamic> json) =>
      CompetitorEntry(
        entryId: json['entryId'] as int,
        carNumber: json['carNumber'] as int?,
        driverFirstName: json['driverFirstName'] as String?,
        driverLastName: json['driverLastName'] as String?,
        navigatorFirstName: json['navigatorFirstName'] as String?,
        navigatorLastName: json['navigatorLastName'] as String?,
      );

  final int entryId;
  final int? carNumber;
  final String? driverFirstName;
  final String? driverLastName;
  final String? navigatorFirstName;
  final String? navigatorLastName;

  String get driverName => _fullName(driverFirstName, driverLastName);
  String get navigatorName => _fullName(navigatorFirstName, navigatorLastName);

  static String _fullName(String? firstName, String? lastName) {
    final name = [
      firstName,
      lastName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    return name.isEmpty ? 'Not provided' : name;
  }
}
