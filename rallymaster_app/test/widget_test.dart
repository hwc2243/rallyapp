import 'package:flutter_test/flutter_test.dart';
import 'package:rallymaster_app/main.dart';

void main() {
  testWidgets('displays the RallyMaster welcome screen', (tester) async {
    await tester.pumpWidget(const RallyMasterApp());

    expect(find.text('RallyMaster'), findsOneWidget);
    expect(find.text('Design your next road rally'), findsOneWidget);
  });
}
