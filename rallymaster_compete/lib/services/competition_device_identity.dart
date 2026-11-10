import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class CompetitionDeviceIdentity {
  static const primaryDeviceIdKey = 'competition_primary_device_id';

  static Future<String> getOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(primaryDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final created = List.generate(
      4,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    await preferences.setString(primaryDeviceIdKey, created);
    return created;
  }

  static Future<String?> read() async {
    final value = (await SharedPreferences.getInstance()).getString(
      primaryDeviceIdKey,
    );
    return value == null || value.isEmpty ? null : value;
  }
}
