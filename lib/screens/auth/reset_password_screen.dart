import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_password.text.length < 6) {
      showErrorSnackBar(context, tr('reset_tooshort'));
      return;
    }
    if (_password.text != _confirm.text) {
      showErrorSnackBar(context, tr('reset_mismatch'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.updatePassword(_password.text);
      await AuthService.signOut();
      if (!mounted) return;
      showSuccessDialog(
        context,
        title: tr('reset_success_title'),
        message: tr('reset_success_msg'),
        onDone: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false),
      );
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
            Text(tr('reset_title'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(tr('reset_sub'),
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: tr('reset_new'),
                hint: '••••••••••',
                icon: Icons.lock_outline,
                obscure: true,
                controller: _password),
            const SizedBox(height: 18),
            AppTextField(
                label: tr('reset_confirm'),
                hint: '••••••',
                icon: Icons.lock_outline,
                obscure: true,
                controller: _confirm),
            const Spacer(),
            PrimaryButton(
                text: _loading ? tr('common_processing') : tr('reset_button'),
                onPressed: _loading ? null : _reset),
          ],
        ),
      ),
    );
  }
}
