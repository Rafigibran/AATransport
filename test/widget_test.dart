import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aatransport/main.dart';

void main() {
  testWidgets('A&A Transport app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AATransportApp());
    // Splash now shows the "Berbagi" stacked logo (tagline is part of the
    // logo image, not a text widget).
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/images/logo-stacked.png');
    expect(image.semanticLabel, 'A&A Transport');
    // Flush splash timer so no pending timer remains
    await tester.pump(const Duration(seconds: 3));
  });
}
