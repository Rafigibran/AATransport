import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Email wajib diisi');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.sendPasswordReset(_email.text);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OtpScreen(email: _email.text.trim())));
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
            const Text('Forgot Your Password?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                'Masukkan email kamu, kami akan mengirimkan kode OTP untuk reset password.',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 26),
            AppTextField(
                label: 'Email',
                hint: 'email@contoh.com',
                icon: Icons.email_outlined,
                controller: _email),
            const Spacer(),
            PrimaryButton(
                text: _loading ? 'Mengirim...' : 'Request OTP',
                onPressed: _loading ? null : _send),
          ],
        ),
      ),
    );
  }
}
