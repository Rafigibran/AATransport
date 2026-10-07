import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
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
      if (mounted)
        showErrorSnackBar(context, 'Kode OTP baru sudah dikirim ke email kamu');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 6) {
      showErrorSnackBar(context, 'Masukkan kode OTP dari email kamu');
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
            const Text('Verify Your Account!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Masukkan kode OTP yang dikirim ke ${widget.email}.',
                style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: 'Kode OTP',
                hint: 'Contoh: 123456',
                icon: Icons.pin_outlined,
                controller: _otp),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                  onPressed: _resend,
                  child: const Text("Tidak menerima OTP? Kirim ulang kode")),
            ),
            const Spacer(),
            PrimaryButton(
                text: _loading ? 'Memverifikasi...' : 'Verify',
                onPressed: _loading ? null : _verify),
          ],
        ),
      ),
    );
  }
}
