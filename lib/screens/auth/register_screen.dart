import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _agree = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty ||
        !isValidEmail(_email.text) ||
        (_phone.text.trim().isNotEmpty &&
            !isValidIndonesianPhone(_phone.text)) ||
        _password.text.length < 6) {
      showErrorSnackBar(context, tr('reg_validation'));
      return;
    }
    if (!_agree) {
      showErrorSnackBar(context, tr('reg_must_agree'));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await AuthService.signUp(
          _name.text, _email.text, _password.text, _phone.text);
      if (!mounted) return;
      if (res.session != null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (_) => false);
      } else {
        showSuccessDialog(
          context,
          title: tr('reg_success_title'),
          message: tr('reg_success_msg'),
          buttonText: tr('reg_go_login'),
          onDone: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false),
        );
      }
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
            Text(tr('reg_title'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('reg_sub'),
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: tr('reg_name'),
                hint: tr('reg_name_hint'),
                icon: Icons.person_outline,
                controller: _name),
            const SizedBox(height: 18),
            AppTextField(
                label: 'Email',
                hint: tr('reg_email_hint'),
                icon: Icons.email_outlined,
                controller: _email),
            const SizedBox(height: 18),
            AppTextField(
                label: tr('reg_phone'),
                hint: tr('reg_phone_hint'),
                icon: Icons.phone_outlined,
                controller: _phone),
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
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  activeColor: AppColors.primary),
              Expanded(
                  child: InkWell(
                      onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(tr('reg_terms_title')),
                              content: SingleChildScrollView(
                                child: Text(tr('reg_terms_body')),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(tr('common_close')),),
                              ],
                            ),
                          ),
                      child: Text(
                          tr('reg_agree'),
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline)))),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(
                text: _loading ? tr('common_processing') : tr('reg_button'),
                onPressed: _loading ? null : _register),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(tr('reg_have_account')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
