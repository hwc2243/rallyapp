import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_allowance.dart';

class TimeAllowanceStore {
  static String _key(int routeId) => 'time_allowances_route_$routeId';

  Future<List<TimeAllowance>> load(int routeId) async {
    final encoded = (await SharedPreferences.getInstance()).getString(
      _key(routeId),
    );
    if (encoded == null) return const [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map((value) => TimeAllowance.fromJson(value as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(int routeId, Iterable<TimeAllowance> allowances) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(routeId),
      jsonEncode(allowances.map((allowance) => allowance.toJson()).toList()),
    );
  }
}
