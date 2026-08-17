import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally_lib/rally_lib.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final role = ref.read(deviceRoleProvider);
      if (role == DeviceRole.controller &&
          !await ref.read(locationServiceProvider).isHardwareReady()) {
        // A Controller requires local GPS. Devices without it remain remote
        // displays and do not expose Controller Bluetooth settings.
        await ref.read(deviceRoleProvider.notifier).setRole(DeviceRole.driver);
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Image(
            image: AssetImage('assets/rally_odometer_logo.png'),
            width: 300, // Reasonable size for a logo
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
