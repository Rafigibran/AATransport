import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'review_summary_screen.dart';

class GuestInfoScreen extends StatefulWidget {
  final BookingDraft draft;
  const GuestInfoScreen({super.key, required this.draft});
  @override
  State<GuestInfoScreen> createState() => _GuestInfoScreenState();
}

class _GuestInfoScreenState extends State<GuestInfoScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _otherName = TextEditingController();
  bool _bookForOthers = false;

  @override
  void initState() {
    super.initState();
    ProfileService.fetchProfile().then((p) {
      if (!mounted || p == null) return;
      setState(() {
        _name.text = (p['full_name'] ?? '').toString();
        _email.text = (p['email'] ?? '').toString();
        _phone.text = (p['phone'] ?? '').toString();
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _otherName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Guest Info'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppTextField(
                label: 'Guest Name',
                hint: 'Nama tamu',
                icon: Icons.person_outline,
                controller: _name),
            const SizedBox(height: 18),
            AppTextField(
                label: 'Email',
                hint: 'email@contoh.com',
                icon: Icons.email_outlined,
                controller: _email),
            const SizedBox(height: 18),
            AppTextField(
                label: 'Phone',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_outlined,
                controller: _phone),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Book for Others'),
              value: _bookForOthers,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _bookForOthers = v),
            ),
            if (_bookForOthers) ...[
              const SizedBox(height: 8),
              AppTextField(
                  label: 'Other Guest Name',
                  hint: 'Nama tamu lain',
                  icon: Icons.person_outline,
                  controller: _otherName),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Continue',
              onPressed: () {
                final guestName =
                    _bookForOthers && _otherName.text.trim().isNotEmpty
                        ? _otherName.text.trim()
                        : _name.text.trim();
                if (guestName.isEmpty ||
                    _email.text.trim().isEmpty ||
                    _phone.text.trim().isEmpty) {
                  showErrorSnackBar(context,
                      'Nama, email, dan nomor handphone tamu wajib diisi');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSummaryScreen(
                      draft: widget.draft,
                      guestName: guestName,
                      guestEmail: _email.text.trim(),
                      guestPhone: _phone.text.trim(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
