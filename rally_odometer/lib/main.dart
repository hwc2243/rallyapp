import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/details_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/navigator_dashboard_screen.dart';
import 'screens/role_selection_screen.dart';
import 'providers/controller_display_view_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WakelockPlus.enable();
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

/// Selects only the local dashboard widget. Controller providers live above
/// this widget in [RallyOdometerApp], so changing the display view does not
/// tear down GPS, odometer accumulation, or Controller BLE publication.
Widget buildDashboardForRole(
  DeviceRole role,
  ControllerDisplayView view,
) {
  switch (role) {
    case DeviceRole.controller:
      return view == ControllerDisplayView.driver
          ? const DriverDashboardScreen(isControllerEngine: true)
          : const NavigatorDashboardScreen(isControllerEngine: true);
    case DeviceRole.driver:
      return const DriverDashboardScreen(isControllerEngine: false);
    case DeviceRole.navigator:
      return const NavigatorDashboardScreen(isControllerEngine: false);
  }
}

class DashboardForRoleScreen extends ConsumerWidget {
  const DashboardForRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buildDashboardForRole(
      ref.watch(deviceRoleProvider),
      ref.watch(controllerDisplayViewProvider),
    );
  }
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
    // These providers activate Controller publication/command handling without
    // modifying the established Controller dashboard widget tree.
    ref.watch(controllerBlePublisherProvider);
    ref.watch(controllerCommandDispatcherProvider);
    return MaterialApp(
      title: 'Rally Odometer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardForRoleScreen(),
        '/odometer': (context) => const DashboardForRoleScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/details': (context) => const DetailsScreen(),
        '/driver': (context) => const DashboardForRoleScreen(),
        '/navigator': (context) => const DashboardForRoleScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
      },
    );
  }
}
