import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'payment_screen.dart';

class ReviewSummaryScreen extends StatefulWidget {
  final BookingDraft draft;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  const ReviewSummaryScreen(
      {super.key,
      required this.draft,
      required this.customerName,
      required this.customerEmail,
      required this.customerPhone});
  @override
  State<ReviewSummaryScreen> createState() => _ReviewSummaryScreenState();
}

class _ReviewSummaryScreenState extends State<ReviewSummaryScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    final channel = paymentChannels.firstWhere(
        (c) => c.code == widget.draft.paymentMethodCode,
        orElse: () => paymentChannels.first);
    if (!channel.supportsAmount(widget.draft.total)) {
      showErrorSnackBar(
          context,
          'Channel ${channel.name} hanya mendukung ${formatRupiah(channel.minAmount)} - ${formatRupiah(channel.maxAmount)}. Kembali dan pilih metode pembayaran lain.');
      return;
    }
    setState(() => _paying = true);
    try {
      final booking = await BookingService.createBooking(widget.draft,
          customerName: widget.customerName,
          customerEmail: widget.customerEmail,
          customerPhone: widget.customerPhone);
      final payment = await BookingService.createPayment(
          booking.id, widget.draft.paymentMethodCode);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PaymentScreen(booking: booking, payment: payment)));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final channelName = paymentChannels
        .firstWhere((c) => c.code == d.paymentMethodCode,
            orElse: () => paymentChannels.first)
        .name;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Review Summary'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarCard(car: d.car, horizontal: true),
            const Text('Rental Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row('Tanggal Ambil', formatDateId(d.pickupDate)),
            _row('Tanggal Kembali', formatDateId(d.returnDate)),
            _row('Penyewa', '${d.passengers}'),
            _row('Mobil', '${d.units} - ${d.serviceType}'),
            _row('Durasi', '${d.days} hari'),
            const Divider(height: 28),
            const Text('Customer Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row('Name', widget.customerName),
            _row('Email', widget.customerEmail),
            _row('Phone', widget.customerPhone),
            const Divider(height: 28),
            const Text('Payment Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row('Harga sewa per hari', formatRupiah(d.car.price)),
            _row('Subtotal', formatRupiah(d.subtotal)),
            if (d.tax > 0)
              _row('Pajak (${_percentLabel(d.settings.taxPercent)})',
                  formatRupiah(d.tax)),
            if (d.fee > 0)
              _row('Biaya layanan (${_percentLabel(d.settings.feePercent)})',
                  formatRupiah(d.fee)),
            if (d.tax == 0 && d.fee == 0)
              _row('Pajak & biaya layanan', formatRupiah(0)),
            const Divider(),
            _row('Total Amount', formatRupiah(d.total), bold: true),
            _row('Payment Method', '$channelName (SakuRupiah)'),
            const SizedBox(height: 30),
            PrimaryButton(
                text: _paying
                    ? 'Memproses Pembayaran...'
                    : 'Bayar ${formatRupiah(d.total)}',
                onPressed: _paying ? null : _pay),
          ],
        ),
      ),
    );
  }

  String _percentLabel(double value) =>
      '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}%';

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k,
            style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                    color: bold ? AppColors.primary : AppColors.textDark))),
      ]),
    );
  }
}
