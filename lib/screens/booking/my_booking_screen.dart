import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import 'e_receipt_screen.dart';
import 'add_review_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});
  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
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

  @override
  Widget build(BuildContext context) {
    final all = MockData.bookings();
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
      body: TabBarView(
        controller: _tab,
        children: ['Upcoming', 'Completed', 'Cancelled'].map((status) {
          final list = all.where((b) => b.status == status).toList();
          if (list.isEmpty)
            return const Center(
                child: Text('No booking yet',
                    style: TextStyle(color: AppColors.textGrey)));
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (_, i) => _BookingCard(booking: list[i]),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  @override
  Widget build(BuildContext context) {
    final isUpcoming = booking.status == 'Upcoming';
    final isCompleted = booking.status == 'Completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
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
                Text('\$${booking.total.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.calendar_month_outlined,
              size: 16, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text('${booking.checkIn}  →  ${booking.checkOut}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          if (isUpcoming) ...[
            Expanded(
                child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EReceiptScreen(booking: booking))),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                    child: const Text('E-Receipt'))),
          ] else if (isCompleted) ...[
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AddReviewScreen(hotel: booking.hotel))),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Add Review'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EReceiptScreen(booking: booking))),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                    child: const Text('E-Receipt'))),
          ] else
            Expanded(
                child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Re-Book'))),
        ]),
      ]),
    );
  }
}
