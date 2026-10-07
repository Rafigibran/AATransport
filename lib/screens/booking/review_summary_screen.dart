import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';

class ReviewSummaryScreen extends StatelessWidget {
  final Hotel hotel;
  const ReviewSummaryScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    const tax = 15.18;
    final total = hotel.price + tax;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Review Summary'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HotelCard(hotel: hotel, horizontal: true),
          const Text('Booking Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          _row('Check In', '09/05/25 | 11:30 AM'),
          _row('Check Out', '12/05/25'),
          _row('Guest', '01'),
          _row('Room', '01'),
          const Divider(height: 28),
          const Text('Guest Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          _row('Name', 'Alul Ahmad'),
          _row('Email', 'alalahmad03@gmail.com'),
          _row('Phone', '+880 1234567891'),
          const Divider(height: 28),
          const Text('Payment Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          _row('Price', '\$${hotel.price.toStringAsFixed(2)}'),
          _row('Tax', '\$${tax.toStringAsFixed(2)}'),
          const Divider(),
          _row('Total Amount', '\$${total.toStringAsFixed(2)}', bold: true),
          _row('Payment Method', 'Cash'),
          const SizedBox(height: 30),
          PrimaryButton(
            text: 'Pay \$${total.toStringAsFixed(2)}',
            onPressed: () => showSuccessDialog(
              context,
              title: 'Payment Successful!',
              message: 'Your booking has been confirmed. Enjoy your stay!',
              onDone: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (_) => false),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k,
            style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(v,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? AppColors.primary : AppColors.textDark)),
      ]),
    );
  }
}
