import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkpoint_crossing.dart';

class CheckpointCrossingStore {
  static String _key(int routeId) => 'checkpoint_crossings_route_$routeId';

  Future<Map<int, CheckpointCrossing>> load(int routeId) async {
    final encoded = (await SharedPreferences.getInstance()).getString(
      _key(routeId),
    );
    if (encoded == null) return {};
    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      return {
        for (final value in values)
          (value as Map<String, dynamic>)['checkpointId'] as int:
              CheckpointCrossing.fromJson(value),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> save(int routeId, Iterable<CheckpointCrossing> crossings) async {
    final encoded = jsonEncode(
      crossings.map((crossing) => crossing.toJson()).toList(),
    );
    await (await SharedPreferences.getInstance()).setString(
      _key(routeId),
      encoded,
    );
  }
}
