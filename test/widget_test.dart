import 'package:flutter_test/flutter_test.dart';
import 'package:hipo_app/main.dart';

void main() {
  testWidgets('Hipo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HipoApp());
    expect(find.text('Check-in to comfort'), findsOneWidget);
    // Flush splash timer so no pending timer remains
    await tester.pump(const Duration(seconds: 3));
  });
}
