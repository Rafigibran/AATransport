import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/car.dart';
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
          title: const Text('E-Receipt'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CarCard(car: booking.car, horizontal: true),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _row('Booking ID', booking.id.substring(0, 8).toUpperCase()),
                _row('Tanggal Ambil', formatDateId(booking.pickupDate)),
                _row('Tanggal Kembali', formatDateId(booking.returnDate)),
                _row('Penyewa', booking.customerName),
                _row('Mobil', '${booking.units} x ${booking.serviceType}'),
                _row('Durasi', '${booking.days} hari'),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _row('Subtotal', formatRupiah(booking.subtotal)),
                _row('Pajak', formatRupiah(booking.tax)),
                _row('Biaya layanan', formatRupiah(booking.fee)),
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
                      text: 'Salin E-Receipt',
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: _receiptText()));
                        if (context.mounted) {
                          showErrorSnackBar(
                              context, 'E-receipt disalin ke clipboard');
                        }
                      })),
            ]),
          ],
        ),
      ),
    );
  }

  String _receiptText() {
    return [
      'E-Receipt A&A Transport',
      'Booking ID: ${booking.id.substring(0, 8).toUpperCase()}',
      'Mobil: ${booking.car.name}',
      'Penyewa: ${booking.customerName}',
      'Tanggal Ambil: ${formatDateId(booking.pickupDate)}',
      'Tanggal Kembali: ${formatDateId(booking.returnDate)}',
      'Durasi: ${booking.days} hari',
      'Subtotal: ${formatRupiah(booking.subtotal)}',
      'Pajak: ${formatRupiah(booking.tax)}',
      'Biaya layanan: ${formatRupiah(booking.fee)}',
      'Total: ${formatRupiah(booking.total)}',
      'Metode Pembayaran: ${booking.paymentMethodCode ?? '-'} (SakuRupiah)',
      'Status Pembayaran: ${booking.paymentStatus}',
      if (booking.trxId != null) 'ID Transaksi: ${booking.trxId}',
    ].join('\n');
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
