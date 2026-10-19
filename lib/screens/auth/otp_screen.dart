import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await AuthService.sendPasswordReset(widget.email);
      if (mounted) {
        showErrorSnackBar(context, tr('otp_resent'));
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 6) {
      showErrorSnackBar(context, tr('otp_required'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.verifyRecoveryOtp(widget.email, _otp.text);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('otp_title'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(tr('otp_sub', {'email': widget.email}),
                style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: tr('otp_label'),
                hint: tr('otp_hint'),
                icon: Icons.pin_outlined,
                controller: _otp),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                  onPressed: _resend,
                  child: Text(tr('otp_resend'))),
            ),
            const Spacer(),
            PrimaryButton(
                text: _loading ? tr('common_processing') : tr('otp_button'),
                onPressed: _loading ? null : _verify),
          ],
        ),
      ),
    );
  }
}
