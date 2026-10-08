import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common_widgets.dart';
import 'review_summary_screen.dart';

class CustomerInfoScreen extends StatefulWidget {
  final BookingDraft draft;
  const CustomerInfoScreen({super.key, required this.draft});
  @override
  State<CustomerInfoScreen> createState() => _CustomerInfoScreenState();
}

class _CustomerInfoScreenState extends State<CustomerInfoScreen> {
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
      appBar: AppBar(
          title: const Text('Customer Info'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppTextField(
                label: 'Customer Name',
                hint: 'Nama penyewa',
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
                  label: 'Other Customer Name',
                  hint: 'Nama penyewa lain',
                  icon: Icons.person_outline,
                  controller: _otherName),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Continue',
              onPressed: () {
                final customerName =
                    _bookForOthers && _otherName.text.trim().isNotEmpty
                        ? _otherName.text.trim()
                        : _name.text.trim();
                if (customerName.isEmpty ||
                    !isValidEmail(_email.text) ||
                    !isValidIndonesianPhone(_phone.text)) {
                  showErrorSnackBar(context,
                      'Nama wajib diisi serta email dan nomor handphone Indonesia harus valid');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSummaryScreen(
                      draft: widget.draft,
                      customerName: customerName,
                      customerEmail: _email.text.trim(),
                      customerPhone: _phone.text.trim(),
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
