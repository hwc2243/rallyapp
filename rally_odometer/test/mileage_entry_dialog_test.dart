import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally_odometer/widgets/mileage_entry_dialog.dart';

void main() {
  testWidgets('CLEAR removes the numerical entry value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MileageEntryDialog(
            initialValue: '123.456',
            title: 'TEST ENTRY',
          ),
        ),
      ),
    );

    expect(find.text('123.456'), findsOneWidget);

    await tester.tap(find.text('CLEAR'));
    await tester.pump();

    expect(find.text('123.456'), findsNothing);
  });
}
