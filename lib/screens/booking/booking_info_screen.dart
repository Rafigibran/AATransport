import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'guest_info_screen.dart';

class BookingInfoScreen extends StatefulWidget {
  final Hotel hotel;
  const BookingInfoScreen({super.key, required this.hotel});
  @override
  State<BookingInfoScreen> createState() => _BookingInfoScreenState();
}

class _BookingInfoScreenState extends State<BookingInfoScreen> {
  int selectedDay = 9;
  String selectedPayment = 'Cash';

  void _openCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Select Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ]),
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.chevron_left),
                Text('June - 2025',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right)
              ]),
          const SizedBox(height: 14),
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Sun'),
                Text('Mon'),
                Text('Tue'),
                Text('Wed'),
                Text('Thu'),
                Text('Fri'),
                Text('Sat')
              ]),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: 30,
            itemBuilder: (_, i) {
              final day = i + 1;
              final selected = day == selectedDay || day == selectedDay + 3;
              return GestureDetector(
                onTap: () => setState(() => selectedDay = day),
                child: Container(
                  decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle),
                  child: Center(
                      child: Text('$day',
                          style: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.textDark,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          PrimaryButton(
              text: 'Continue', onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  void _openPayment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Methods',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),
              RadioListTile<String>(
                  value: 'Cash',
                  groupValue: selectedPayment,
                  onChanged: (v) => setState(() => selectedPayment = v!),
                  title: const Text('Cash'),
                  secondary: const Icon(Icons.money, color: AppColors.primary)),
              RadioListTile<String>(
                  value: 'Mastercard ****5432',
                  groupValue: selectedPayment,
                  onChanged: (v) => setState(() => selectedPayment = v!),
                  title: const Text('Mastercard ****5432'),
                  secondary:
                      const Icon(Icons.credit_card, color: AppColors.primary)),
              ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  title: const Text('Add New Card'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddCardScreen()));
                  }),
              const SizedBox(height: 10),
              PrimaryButton(
                  text: 'Continue', onPressed: () => Navigator.pop(context)),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Booking Info'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          HotelCard(hotel: widget.hotel, horizontal: true),
          _field('Check In', '09/05/25', Icons.calendar_month_outlined,
              onTap: _openCalendar),
          _field('Check Out', '12/05/25', Icons.calendar_month_outlined,
              onTap: _openCalendar),
          const Row(children: [
            Expanded(
                child: AppTextField(
                    label: 'Guest',
                    hint: '1 Guest',
                    icon: Icons.person_outline)),
            SizedBox(width: 12),
            Expanded(
                child: AppTextField(
                    label: 'Room', hint: '1 Room', icon: Icons.bed_outlined)),
          ]),
          const SizedBox(height: 18),
          const AppTextField(
              label: 'Room Type',
              hint: 'Economy Room',
              icon: Icons.meeting_room_outlined,
              suffix: Icon(Icons.keyboard_arrow_down)),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(selectedPayment),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: _openPayment,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
              text: 'Continue',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GuestInfoScreen(hotel: widget.hotel)))),
        ]),
      ),
    );
  }

  Widget _field(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Icon(icon, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 12),
                Text(value)
              ])),
        ),
      ]),
    );
  }
}

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Add New Card'), leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            height: 190,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(24)),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('2569 **** **** 5432',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Icon(Icons.credit_card, color: Colors.white)
                      ]),
                  Spacer(),
                  Text('Esther Howard', style: TextStyle(color: Colors.white)),
                  Text('02/30', style: TextStyle(color: Colors.white70)),
                ]),
          ),
          const SizedBox(height: 24),
          const AppTextField(
              label: 'Card Holder',
              hint: 'Alul Ahmad',
              icon: Icons.person_outline),
          const SizedBox(height: 16),
          const AppTextField(
              label: 'Card Number',
              hint: '2569 **** **** 5432',
              icon: Icons.credit_card_outlined),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: AppTextField(label: 'Expiry', hint: '02/30')),
            SizedBox(width: 12),
            Expanded(
                child: AppTextField(label: 'CVV', hint: '900', obscure: true))
          ]),
          const Spacer(),
          PrimaryButton(
              text: 'Add Card',
              onPressed: () => showSuccessDialog(context,
                  title: 'Successfully added card!',
                  message: 'Your card has been added successfully.',
                  onDone: () => Navigator.pop(context))),
        ]),
      ),
    );
  }
}
