import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
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
            const Text('Enter your email address to request a password reset.',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 26),
            const AppTextField(
                label: 'Email',
                hint: 'alalahmad03@gmail.com',
                icon: Icons.email_outlined),
            const SizedBox(height: 14),
            const Text("Don't receive OTP? Re-send Code",
                style: TextStyle(color: AppColors.primary, fontSize: 13)),
            const Spacer(),
            PrimaryButton(
                text: 'Request OTP',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OtpScreen()))),
          ],
        ),
      ),
    );
  }
}
