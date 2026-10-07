import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sign in to continue your journey',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            const AppTextField(
                label: 'Email',
                hint: 'alalahmad03@gmail.com',
                icon: Icons.email_outlined),
            const SizedBox(height: 18),
            const AppTextField(
                label: 'Password',
                hint: '••••••••••',
                icon: Icons.lock_outline,
                obscure: true,
                suffix: Icon(Icons.visibility_off_outlined, size: 20)),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary),
                const Text('Remember Me'),
                const Spacer(),
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password')),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
                text: 'Log In',
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false)),
            const SizedBox(height: 22),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Text('Or', style: TextStyle(color: AppColors.textGrey))),
              Expanded(child: Divider())
            ]),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                    child: _SocialButton(
                        label: 'Google', icon: Icons.g_mobiledata)),
                const SizedBox(width: 14),
                Expanded(
                    child:
                        _SocialButton(label: 'Facebook', icon: Icons.facebook)),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Don't have an account? Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: AppColors.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }
}
