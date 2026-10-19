import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'my_booking_screen.dart';

/// Official Haluna Travel WhatsApp (chat only, no payment gateway).
/// Local format 085863701489 -> international 6285863701489 for wa.me links.
const String kWhatsAppNumber = '6285863701489';

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
  bool _sending = false;
  String? _waUrl;

  String _buildWhatsAppMessage(Booking booking) {
    final d = widget.draft;
    final lines = [
      tr('wa_greet'),
      '',
      '${tr('wa_car')}: ${d.car.name}',
      '${tr('wa_pickup')}: ${formatDate(d.pickupDate)}',
      '${tr('wa_return')}: ${formatDate(d.returnDate)}',
      '${tr('wa_duration')}: ${tr('wa_days', {'n': '${d.days}'})}',
      '${tr('wa_units')}: ${d.units}',
      '${tr('wa_service')}: ${d.serviceType}',
      '${tr('wa_total')}: ${formatMoney(d.total)}',
      '',
      '${tr('wa_name')}: ${widget.customerName}',
      'Email: ${widget.customerEmail}',
      '${tr('wa_phone')}: ${widget.customerPhone}',
      '${tr('wa_booking_id')}: ${booking.id.substring(0, 8).toUpperCase()}',
    ];
    return lines.join('\n');
  }

  Future<void> _openWhatsApp() async {
    if (_waUrl == null) return;
    final uri = Uri.tryParse(_waUrl!);
    final opened =
        uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showErrorSnackBar(context, tr('rs_wa_fail'));
    }
  }

  Future<void> _order() async {
    setState(() => _sending = true);
    try {
      final booking = await BookingService.createBooking(widget.draft,
          customerName: widget.customerName,
          customerEmail: widget.customerEmail,
          customerPhone: widget.customerPhone);
      final message = _buildWhatsAppMessage(booking);
      _waUrl =
          'https://wa.me/$kWhatsAppNumber?text=${Uri.encodeComponent(message)}';
      if (!mounted) return;
      await _openWhatsApp();
      if (!mounted) return;
      showSuccessDialog(
        context,
        title: tr('rs_wa_title'),
        message: tr('rs_wa_msg'),
        buttonText: tr('mb_title'),
        onDone: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) => const MyBookingScreen()),
            (_) => false),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('rs_title')), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarCard(car: d.car, horizontal: true),
            Text(tr('rs_rental'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row(tr('rs_pickup'), formatDate(d.pickupDate)),
            _row(tr('rs_return'), formatDate(d.returnDate)),
            _row(tr('rs_passengers'), '${d.passengers}'),
            _row(tr('rs_cars'), '${d.units} - ${d.serviceType}'),
            _row(tr('rs_duration'), tr('rs_days', {'n': '${d.days}'})),
            const Divider(height: 28),
            Text(tr('rs_customer'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row(tr('rs_name'), widget.customerName),
            _row('Email', widget.customerEmail),
            _row(tr('rs_phone'), widget.customerPhone),
            const Divider(height: 28),
            Text(tr('rs_payment'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            _row(tr('rs_price_day'), formatMoney(d.car.price)),
            _row(tr('rs_subtotal'), formatMoney(d.subtotal)),
            if (d.tax > 0)
              _row(
                  tr('rs_tax', {
                    'p': _percentLabel(d.settings.taxPercent)
                  }),
                  formatMoney(d.tax)),
            if (d.fee > 0)
              _row(
                  tr('rs_fee', {
                    'p': _percentLabel(d.settings.feePercent)
                  }),
                  formatMoney(d.fee)),
            if (d.tax == 0 && d.fee == 0)
              _row(tr('rs_no_taxfee'), formatMoney(0)),
            const Divider(),
            _row(tr('rs_total'), formatMoney(d.total), bold: true),
            _row(tr('rs_method'), tr('rs_method_wa')),
            const SizedBox(height: 30),
            PrimaryButton(
                text: _sending
                    ? tr('rs_ordering')
                    : tr('rs_order', {'total': formatMoney(d.total)}),
                onPressed: _sending ? null : _order),
            if (_waUrl != null) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                  text: tr('rs_wa_open'),
                  isOutline: true,
                  onPressed: _openWhatsApp),
            ],
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
