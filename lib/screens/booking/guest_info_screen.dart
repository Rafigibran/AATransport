import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'review_summary_screen.dart';

class GuestInfoScreen extends StatefulWidget {
  final Hotel hotel;
  const GuestInfoScreen({super.key, required this.hotel});
  @override
  State<GuestInfoScreen> createState() => _GuestInfoScreenState();
}

class _GuestInfoScreenState extends State<GuestInfoScreen> {
  bool bookForOthers = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Guest Info'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const AppTextField(
              label: 'Guest Name',
              hint: 'Alul Ahmad',
              icon: Icons.person_outline),
          const SizedBox(height: 18),
          const AppTextField(
              label: 'Email',
              hint: 'alalahmad03@gmail.com',
              icon: Icons.email_outlined),
          const SizedBox(height: 18),
          const AppTextField(
              label: 'Phone',
              hint: '+880 1234567891',
              icon: Icons.phone_outlined),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Book for Others'),
            value: bookForOthers,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => bookForOthers = v),
          ),
          if (bookForOthers) ...[
            const SizedBox(height: 8),
            const AppTextField(
                label: 'Other Guest Name',
                hint: 'Enter name',
                icon: Icons.person_outline),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
              text: 'Continue',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ReviewSummaryScreen(hotel: widget.hotel)))),
        ]),
      ),
    );
  }
}
