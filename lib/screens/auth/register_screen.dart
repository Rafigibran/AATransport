import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Let's Get Started!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Create an account to continue',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            const AppTextField(
                label: 'Full Name',
                hint: 'Alul Ahmad',
                icon: Icons.person_outline),
            const SizedBox(height: 18),
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
            const SizedBox(height: 16),
            Row(children: [
              Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary),
              const Expanded(
                  child: Text('I agree to the Terms and Privacy Policy',
                      style: TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(
                text: 'Register',
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false)),
            const SizedBox(height: 22),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Or')),
              Expanded(child: Divider())
            ]),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))))),
              const SizedBox(width: 14),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.facebook),
                      label: const Text('Facebook'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))))),
            ]),
            const SizedBox(height: 24),
            Center(
                child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Already have an account? Log In'))),
          ],
        ),
      ),
    );
  }
}
