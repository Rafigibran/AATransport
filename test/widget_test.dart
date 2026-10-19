import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haluna_travel/main.dart';
import 'package:haluna_travel/models/car.dart';
import 'package:haluna_travel/l10n/app_strings.dart';
import 'package:haluna_travel/screens/booking/review_summary_screen.dart';
import 'package:haluna_travel/utils/format.dart';

Car _testCar() => const Car(
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

void main() {
  test('booking total defaults to zero tax and zero fee', () {
    final draft = BookingDraft(
      car: _testCar(),
      pickupDate: DateTime(2026, 10, 10),
      returnDate: DateTime(2026, 10, 13),
      passengers: 2,
      units: 1,
      serviceType: 'Dengan Sopir',
      paymentMethodCode: 'WHATSAPP',
    );

    expect(draft.subtotal, 1050000);
    expect(draft.tax, 0);
    expect(draft.fee, 0);
    expect(draft.total, 1050000);
  });

  test('admin-enabled tax and fee percentages are applied separately', () {
    final draft = BookingDraft(
      car: _testCar(),
      pickupDate: DateTime(2026, 10, 10),
      returnDate: DateTime(2026, 10, 12),
      passengers: 2,
      units: 2,
      serviceType: 'Lepas Kunci',
      paymentMethodCode: 'WHATSAPP',
      settings: const AppSettings(taxPercent: 5, feePercent: 2.5),
    );

    expect(draft.subtotal, 1400000);
    expect(draft.tax, 70000);
    expect(draft.fee, 35000);
    expect(draft.total, 1505000);
  });

  test('money formatting follows the system language', () {
    AppStrings.isEnglish = false;
    expect(formatMoney(1500000), 'Rp1.500.000');
    AppStrings.isEnglish = true;
    // 1.500.000 IDR / 17000 = ~88 USD
    expect(formatMoney(1500000), '\$88');
    AppStrings.isEnglish = false;
  });

  test('whatsapp order message uses the official number', () {
    expect(kWhatsAppNumber, isNotEmpty);
  });

  testWidgets('Haluna Travel app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HalunaTravelApp());
    // Splash shows the Haluna Travel logo PNG.
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName,
        'assets/images/logo-haluna.png');
    expect(logo.semanticLabel, 'Haluna Travel');
    // Flush splash timer so no pending timer remains
    await tester.pump(const Duration(seconds: 3));
  });
}
