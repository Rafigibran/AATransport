import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
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
        child: Column(
          children: [
            HotelCard(hotel: booking.hotel, horizontal: true),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _row('Booking ID', booking.id.substring(0, 8).toUpperCase()),
                _row('Check In', formatDateId(booking.checkIn)),
                _row('Check Out', formatDateId(booking.checkOut)),
                _row('Guest', booking.guestName),
                _row('Room', '${booking.rooms} x ${booking.roomType}'),
                _row('Durasi', '${booking.nights} malam'),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _row('Subtotal', formatRupiah(booking.subtotal)),
                _row('Pajak & biaya layanan', formatRupiah(booking.tax)),
                const Divider(),
                _row('Total', formatRupiah(booking.total), bold: true),
                _row('Payment Method',
                    '${booking.paymentMethodCode ?? '-'} (SakuRupiah)'),
                _row('Payment Status', booking.paymentStatus),
                if (booking.trxId != null) _row('ID Transaksi', booking.trxId!),
              ]),
            ),
            const SizedBox(height: 22),
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
                      text: 'Back',
                      isOutline: true,
                      onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 14),
              Expanded(
                  child: PrimaryButton(
                      text: 'Download',
                      onPressed: () => showErrorSnackBar(
                          context, 'E-receipt ditampilkan di halaman ini'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: AppColors.textGrey)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.w600))),
        ]),
      );
}
