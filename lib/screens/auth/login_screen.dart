import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      showErrorSnackBar(context, tr('login_required'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.signIn(_email.text, _password.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('login_title'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('login_sub'),
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: 'Email',
                hint: tr('reg_email_hint'),
                icon: Icons.email_outlined,
                controller: _email),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Password',
              hint: '••••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              controller: _password,
              suffix: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen())),
                child: Text(tr('login_forgot')),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
                text: _loading ? tr('common_processing') : tr('login_button'),
                onPressed: _loading ? null : _login),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text(tr('login_no_account')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
