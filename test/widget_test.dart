import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aatransport/main.dart';
import 'package:aatransport/models/car.dart';

void main() {
  test('booking total defaults to zero tax and zero fee', () {
    const car = Car(
      id: 'car-1',
      name: 'Toyota Avanza',
      location: 'Makassar',
      image: '',
      photos: [],
      price: 350000,
      rating: 4.6,
      reviews: 0,
      description: '',
      features: [],
    );
    final draft = BookingDraft(
      car: car,
      pickupDate: DateTime(2026, 10, 10),
      returnDate: DateTime(2026, 10, 13),
      passengers: 2,
      units: 1,
      serviceType: 'Dengan Sopir',
      paymentMethodCode: 'QRISC',
    );

    expect(draft.subtotal, 1050000);
    expect(draft.tax, 0);
    expect(draft.fee, 0);
    expect(draft.total, 1050000);
  });

  test('admin-enabled tax and fee percentages are applied separately', () {
    const car = Car(
      id: 'car-1',
      name: 'Toyota Avanza',
      location: 'Makassar',
      image: '',
      photos: [],
      price: 350000,
      rating: 4.6,
      reviews: 0,
      description: '',
      features: [],
    );
    final draft = BookingDraft(
      car: car,
      pickupDate: DateTime(2026, 10, 10),
      returnDate: DateTime(2026, 10, 12),
      passengers: 2,
      units: 2,
      serviceType: 'Lepas Kunci',
      paymentMethodCode: 'QRISC',
      settings: const AppSettings(taxPercent: 5, feePercent: 2.5),
    );

    expect(draft.subtotal, 1400000);
    expect(draft.tax, 70000);
    expect(draft.fee, 35000);
    expect(draft.total, 1505000);
  });

  test('payment channels expose supported amount ranges', () {
    final qris =
        paymentChannels.firstWhere((channel) => channel.code == 'QRIS');
    final qrisc =
        paymentChannels.firstWhere((channel) => channel.code == 'QRISC');
    expect(qris.supportsAmount(2000000), isTrue);
    expect(qris.supportsAmount(2500000), isFalse);
    expect(qrisc.supportsAmount(2500000), isTrue);
    expect(
      paymentChannels.map((channel) => channel.code).toSet().length,
      paymentChannels.length,
    );
  });

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
