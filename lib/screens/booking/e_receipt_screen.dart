import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EReceiptScreen extends StatelessWidget {
  final Booking booking;
  const EReceiptScreen({super.key, required this.booking});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('E-Receipt'),
          leading: const BackButton(),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
          ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          HotelCard(hotel: booking.hotel, horizontal: true),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _row('Booking ID', booking.id),
              _row('Check In', booking.checkIn),
              _row('Check Out', booking.checkOut),
              _row('Guest', 'Alul Ahmad'),
              _row('Room', '1 Room'),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _row('Price', '\$${booking.hotel.price.toStringAsFixed(2)}'),
              _row('Tax', '\$15.18'),
              const Divider(),
              _row('Total', '\$${booking.total.toStringAsFixed(2)}',
                  bold: true),
              _row('Payment Method', 'Cash'),
            ]),
          ),
          const SizedBox(height: 22),
          // Fake barcode
          Container(
            height: 70,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                    36,
                    (i) => Container(
                        width: i % 3 == 0 ? 3 : 1.6,
                        height: 44,
                        color: Colors.black87))),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: PrimaryButton(
                    text: 'Back to Home',
                    isOutline: true,
                    onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 14),
            Expanded(child: PrimaryButton(text: 'Download', onPressed: () {})),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: AppColors.textGrey)),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ]),
      );
}
