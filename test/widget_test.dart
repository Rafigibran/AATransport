import 'package:flutter_test/flutter_test.dart';
import 'package:aatransport/main.dart';

void main() {
  testWidgets('A&A Transport app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AATransportApp());
    expect(find.text('Travel in comfort'), findsOneWidget);
    // Flush splash timer so no pending timer remains
    await tester.pump(const Duration(seconds: 3));
  });
}
