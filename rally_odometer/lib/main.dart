import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/odometer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Lock to landscape as per PRD
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RallyOdometerApp(),
    ),
  );
}

class RallyOdometerApp extends StatelessWidget {
  const RallyOdometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rally Odometer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/odometer': (context) => const OdometerScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/details': (context) => const DetailsScreen(),
      },
    );
  }
}
