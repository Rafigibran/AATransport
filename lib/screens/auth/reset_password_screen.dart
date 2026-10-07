import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Your Password!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Create a new password for your account.',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            const AppTextField(
                label: 'New Password',
                hint: '••••••••••',
                icon: Icons.lock_outline,
                obscure: true,
                suffix: Icon(Icons.visibility_outlined, size: 20)),
            const SizedBox(height: 18),
            const AppTextField(
                label: 'Confirm Password',
                hint: '••••••',
                icon: Icons.lock_outline,
                obscure: true,
                suffix: Icon(Icons.visibility_off_outlined, size: 20)),
            const Spacer(),
            PrimaryButton(
              text: 'Reset Password',
              onPressed: () => showSuccessDialog(
                context,
                title: 'Reset Your Password!',
                message: 'Your password has been successfully reset.',
                onDone: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
