import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rally_odometer/main.dart';
import 'package:rally_lib/rally_lib.dart';

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

  testWidgets(
    'calculated calibration factor requires confirmation before it is saved',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'totalDistance': 1609.344});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const RallyOdometerApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final measuredModeToggle = find.byTooltip('Use measured mileage');
      final measuredMileageField = find.byType(TextField).last;
      await tester.ensureVisible(measuredModeToggle);
      await tester.pumpAndSettle();
      await tester.tap(measuredModeToggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(measuredMileageField);
      await tester.pumpAndSettle();
      await tester.tap(measuredMileageField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CLEAR'));
      await tester.tap(find.text('2').last);
      await tester.tap(find.text('.').last);
      await tester.tap(find.text('0').last);
      await tester.tap(find.text('0').last);
      await tester.tap(find.text('0').last);
      await tester.tap(find.text('SET'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      expect(find.text('CURRENT FACTOR: 1.00000'), findsOneWidget);
      expect(find.text('CALCULATED NEW FACTOR: 2.00000'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(prefs.getDouble('calibrationFactor'), isNull);

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRM'));
      await tester.pumpAndSettle();
      expect(prefs.getDouble('calibrationFactor'), closeTo(2.0, 1e-9));
    },
  );
}
