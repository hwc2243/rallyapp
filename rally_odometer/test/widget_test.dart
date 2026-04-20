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
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RallyOdometerApp(),
      ),
    );

    // Wait for the splash screen (2 seconds) to finish and navigate
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the odometer screen is displayed
    expect(find.textContaining('TOTAL'), findsOneWidget);
    expect(find.textContaining('INTERVAL'), findsOneWidget);
    expect(find.textContaining('SPD: 0.0 MPH'), findsOneWidget);
  });
}
