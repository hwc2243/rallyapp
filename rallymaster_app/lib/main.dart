import 'package:flutter/material.dart';

void main() => runApp(const RallyMasterApp());

class RallyMasterApp extends StatelessWidget {
  const RallyMasterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RallyMaster',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B1A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF071523),
      useMaterial3: true,
    ),
    home: const WelcomeScreen(),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/rallymaster_logo.png',
                width: 144,
                height: 144,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'RallyMaster',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Design your next road rally',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
