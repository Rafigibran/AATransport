import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'add_review_screen.dart';
import 'e_receipt_screen.dart';
import 'review_summary_screen.dart' show kWhatsAppNumber;

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
        title: Text(tr('mb_title')),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: tr('mb_upcoming')),
            Tab(text: tr('mb_completed')),
            Tab(text: tr('mb_cancelled')),
          ],
        ),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(message: tr('mb_fail'), onRetry: _reload);
          }
          final all = snapshot.data ?? [];
          return TabBarView(
            controller: _tab,
            children: ['upcoming', 'completed', 'cancelled'].map((tab) {
              final list = all.where((b) => b.tabStatus == tab).toList();
              if (list.isEmpty) {
                return ErrorView(message: tr('mb_empty'));
              }
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

  Future<void> _contactWhatsApp(BuildContext context) async {
    final message = [
      tr('wa_greet'),
      '',
      '${tr('wa_car')}: ${booking.car.name}',
      '${tr('wa_pickup')}: ${formatDate(booking.pickupDate)}',
      '${tr('wa_return')}: ${formatDate(booking.returnDate)}',
      '${tr('wa_total')}: ${formatMoney(booking.total)}',
      '${tr('wa_booking_id')}: ${booking.id.substring(0, 8).toUpperCase()}',
    ].join('\n');
    final uri = Uri.parse(
        'https://wa.me/$kWhatsAppNumber?text=${Uri.encodeComponent(message)}');
    final opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showErrorSnackBar(context, tr('rs_wa_fail'));
    }
  }

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
                child: Image.network(booking.car.image,
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
                    Text(booking.car.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(booking.car.location,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(formatMoney(booking.total),
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
                '${formatDate(booking.pickupDate)}  →  ${formatDate(booking.returnDate)}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            if (isUpcoming) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: booking.isPaid
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(tr('mb_cancel_title')),
                              content: Text(tr('mb_cancel_msg')),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(tr('common_no'))),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(tr('mb_yes_cancel'))),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          try {
                            await BookingService.cancelBooking(booking.id);
                            onChanged();
                          } catch (e) {
                            if (context.mounted) showErrorSnackBar(context, e);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(booking.isPaid
                      ? tr('mb_paid')
                      : tr('mb_cancel_btn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (booking.isPaid || booking.status == 'expired') {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EReceiptScreen(booking: booking)));
                      onChanged();
                      return;
                    }
                    // Unpaid booking: continue confirmation via WhatsApp.
                    await _contactWhatsApp(context);
                  },
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(booking.isPaid
                      ? tr('mb_receipt')
                      : tr('mb_wa')),
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
                                car: booking.car, bookingId: booking.id)));
                    onChanged();
                  },
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(tr('mb_review')),
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
                  child: Text(tr('mb_receipt')),
                ),
              ),
            ] else
              Expanded(
                child: OutlinedButton(
                  onPressed: onChanged,
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(tr('common_refresh')),
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
        ? tr('mb_confirmed')
        : booking.status == 'cancelled'
            ? tr('mb_cancelled_st')
            : booking.status == 'expired'
                ? tr('mb_expired')
                : tr('mb_pending');
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
