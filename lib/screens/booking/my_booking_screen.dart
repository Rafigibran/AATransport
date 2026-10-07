import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'add_review_screen.dart';
import 'e_receipt_screen.dart';
import 'payment_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});
  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<List<Booking>> _future = BookingService.fetchBookings();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = BookingService.fetchBookings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled')
          ],
        ),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const LoadingView();
          if (snapshot.hasError)
            return ErrorView(
                message: 'Gagal memuat booking.', onRetry: _reload);
          final all = snapshot.data ?? [];
          return TabBarView(
            controller: _tab,
            children: ['upcoming', 'completed', 'cancelled'].map((tab) {
              final list = all.where((b) => b.tabStatus == tab).toList();
              if (list.isEmpty)
                return const ErrorView(
                    message: 'Belum ada booking di kategori ini.');
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _BookingCard(
                    booking: list[i],
                    onChanged: _reload,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onChanged;
  const _BookingCard({required this.booking, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = booking.tabStatus == 'upcoming';
    final isCompleted = booking.tabStatus == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(booking.hotel.image,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 78, height: 78, color: Colors.grey.shade200))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.hotel.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(booking.hotel.location,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(formatRupiah(booking.total),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _statusChip(),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_month_outlined,
                size: 16, color: AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
                '${formatDateId(booking.checkIn)}  →  ${formatDateId(booking.checkOut)}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            if (isUpcoming) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await BookingService.cancelBooking(booking.id);
                    onChanged();
                  },
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!booking.isPaid &&
                        (booking.checkoutUrl != null ||
                            booking.paymentNo != null)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            booking: booking,
                            payment: PaymentResult(
                                checkoutUrl: booking.checkoutUrl,
                                paymentNo: booking.paymentNo,
                                qrString: booking.qrString,
                                trxId: booking.trxId,
                                methodCode: booking.paymentMethodCode),
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EReceiptScreen(booking: booking)));
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(booking.isPaid ? 'E-Receipt' : 'Bayar / Cek'),
                ),
              ),
            ] else if (isCompleted) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddReviewScreen(
                                hotel: booking.hotel, bookingId: booking.id)));
                    onChanged();
                  },
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Add Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EReceiptScreen(booking: booking))),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: const Text('E-Receipt'),
                ),
              ),
            ] else
              Expanded(
                child: OutlinedButton(
                  onPressed: onChanged,
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Refresh'),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final paid = booking.isPaid;
    final label = paid
        ? 'Terkonfirmasi'
        : booking.status == 'cancelled'
            ? 'Dibatalkan'
            : booking.status == 'expired'
                ? 'Kedaluwarsa'
                : 'Menunggu Pembayaran';
    final color = paid
        ? Colors.green
        : booking.tabStatus == 'cancelled'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
