import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rally_odometer/main.dart';
import 'package:rally_odometer/providers/settings_provider.dart';

void main() {
  testWidgets('Odometer screen loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const RallyOdometerApp(),
      ),
    );

    // Wait for the splash screen (2 seconds) to finish and navigate
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the odometer screen is displayed
    expect(find.textContaining('TOTAL'), findsOneWidget);
    expect(find.textContaining('INTERVAL'), findsOneWidget);
    expect(find.textContaining('SPEED: 0.0 MPH'), findsOneWidget);
    expect(find.text('BUMP+'), findsOneWidget);
    expect(find.text('BUMP-'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('LIVE DETAILS'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Require Double-Tap for Bumps'), findsOneWidget);
  });
}
