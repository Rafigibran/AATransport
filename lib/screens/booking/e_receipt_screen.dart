import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/car.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../l10n/app_strings.dart';
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
                _row(tr('er_id'), booking.id.substring(0, 8).toUpperCase()),
                _row(tr('er_pickup'), formatDate(booking.pickupDate)),
                _row(tr('er_return'), formatDate(booking.returnDate)),
                _row(tr('er_renter'), booking.customerName),
                _row(tr('er_cars'), '${booking.units} x ${booking.serviceType}'),
                _row(tr('er_duration'), tr('er_days', {'n': '${booking.days}'})),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _row(tr('er_subtotal'), formatMoney(booking.subtotal)),
                _row(tr('er_tax'), formatMoney(booking.tax)),
                _row(tr('er_fee'), formatMoney(booking.fee)),
                const Divider(),
                _row(tr('er_total'), formatMoney(booking.total), bold: true),
                _row(tr('er_method'), tr('er_method_wa')),
                _row(tr('er_status'), booking.paymentStatus),
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
                      text: tr('common_back'),
                      isOutline: true,
                      onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 14),
              Expanded(
                  child: PrimaryButton(
                      text: tr('er_copy'),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: _receiptText()));
                        if (context.mounted) {
                          showErrorSnackBar(
                              context, tr('er_copied'));
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
      tr('er_header'),
      '${tr('er_id')}: ${booking.id.substring(0, 8).toUpperCase()}',
      '${tr('wa_car')}: ${booking.car.name}',
      '${tr('er_renter')}: ${booking.customerName}',
      '${tr('er_pickup')}: ${formatDate(booking.pickupDate)}',
      '${tr('er_return')}: ${formatDate(booking.returnDate)}',
      '${tr('er_duration')}: ${tr('er_days', {'n': '${booking.days}'})}',
      '${tr('er_subtotal')}: ${formatMoney(booking.subtotal)}',
      '${tr('er_tax')}: ${formatMoney(booking.tax)}',
      '${tr('er_fee')}: ${formatMoney(booking.fee)}',
      '${tr('er_total')}: ${formatMoney(booking.total)}',
      '${tr('er_method')}: ${tr('er_method_wa')}',
      '${tr('er_status')}: ${booking.paymentStatus}',
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
