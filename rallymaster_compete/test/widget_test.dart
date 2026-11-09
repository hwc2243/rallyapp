import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rallymaster_compete/main.dart';

void main() {
  testWidgets('displays the RallyMaster Compete shell', (tester) async {
    await tester.pumpWidget(const RallyMasterCompeteApp());

    expect(find.text('RallyMaster Compete'), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
