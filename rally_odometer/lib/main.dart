import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'providers/odometer_provider.dart';
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

class RallyOdometerApp extends ConsumerStatefulWidget {
  const RallyOdometerApp({super.key});

  @override
  ConsumerState<RallyOdometerApp> createState() => _RallyOdometerAppState();
}

class _RallyOdometerAppState extends ConsumerState<RallyOdometerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (appLifecycleState == AppLifecycleState.paused ||
        appLifecycleState == AppLifecycleState.inactive ||
        appLifecycleState == AppLifecycleState.detached) {
      ref.read(odometerProvider.notifier).persistNow();
    }
  }

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
