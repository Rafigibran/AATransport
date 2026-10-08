import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aatransport/main.dart';

void main() {
  testWidgets('A&A Transport app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AATransportApp());
    // Splash now shows the "Berbagi" stacked logo as an SVG asset
    // (tagline is part of the logo artwork, not a text widget).
    final logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect((logo.bytesLoader as SvgAssetLoader).assetName,
        'assets/images/logo-stacked.svg');
    expect(logo.semanticsLabel, 'A&A Transport');
    // Flush splash timer so no pending timer remains
    await tester.pump(const Duration(seconds: 3));
  });
}
