import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rallymaster_app/main.dart';

void main() {
  testWidgets('displays the RallyMaster authentication gate', (tester) async {
    await tester.pumpWidget(const RallyMasterApp());

    expect(find.text('RallyMaster'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
