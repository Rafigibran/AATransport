import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final PaymentResult payment;
  const PaymentScreen(
      {super.key, required this.booking, required this.payment});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _checking = false;
  String? _status;

  Future<void> _openCheckout() async {
    final url = widget.payment.checkoutUrl ?? widget.booking.checkoutUrl;
    if (url == null || url.isEmpty) {
      showErrorSnackBar(context,
          'Checkout URL tidak tersedia. Gunakan nomor pembayaran / QR di bawah.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final status = await BookingService.checkPayment(widget.booking.id);
      setState(() => _status = status);
      if (!mounted) return;
      if (status == 'berhasil') {
        showSuccessDialog(
          context,
          title: 'Payment Successful!',
          message: 'Pembayaran berhasil dan booking kamu sudah terkonfirmasi.',
          onDone: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 1)),
              (_) => false),
        );
      } else if (status == 'expired') {
        showErrorSnackBar(context,
            'Pembayaran sudah kedaluwarsa. Silakan buat booking baru.');
      } else {
        showErrorSnackBar(context,
            'Pembayaran masih pending. Selesaikan pembayaran lalu cek lagi.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return Scaffold(
      appBar:
          AppBar(title: const Text('Pembayaran'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HotelCard(hotel: widget.booking.hotel, horizontal: true),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selesaikan Pembayaran via SakuRupiah',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),
                  _row('Metode',
                      p.methodCode ?? widget.booking.paymentMethodCode ?? '-'),
                  _row('Total', formatRupiah(widget.booking.total)),
                  if (p.paymentNo != null)
                    _row('No. Pembayaran / VA', p.paymentNo!),
                  if (p.trxId != null) _row('ID Transaksi', p.trxId!),
                  _row('Status', _status ?? widget.booking.paymentStatus),
                ],
              ),
            ),
            if (p.qrString != null && p.qrString!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 72, color: AppColors.primary),
                    const SizedBox(height: 10),
                    const Text('Kode QR / payload pembayaran:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(p.qrString!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(text: 'Bayar Sekarang', onPressed: _openCheckout),
            const SizedBox(height: 12),
            PrimaryButton(
                text: _checking ? 'Mengecek...' : 'Cek Status Pembayaran',
                isOutline: true,
                onPressed: _checking ? null : _checkStatus),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainScreen(initialIndex: 1)),
                    (_) => false),
                child: const Text('Lihat Booking Saya'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: AppColors.textGrey)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
