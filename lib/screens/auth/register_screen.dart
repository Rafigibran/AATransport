import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
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
      showErrorSnackBar(context,
          'Nama wajib diisi, email/nomor handphone harus valid, dan password minimal 6 karakter');
      return;
    }
    if (!_agree) {
      showErrorSnackBar(
          context, 'Kamu perlu menyetujui Syarat & Kebijakan Privasi');
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
          title: 'Registrasi Berhasil',
          message: 'Silakan cek email kamu untuk konfirmasi akun, lalu login.',
          buttonText: 'Ke Halaman Login',
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
            const Text("Let's Get Started!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Buat akun untuk melanjutkan',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            AppTextField(
                label: 'Full Name',
                hint: 'Nama lengkap',
                icon: Icons.person_outline,
                controller: _name),
            const SizedBox(height: 18),
            AppTextField(
                label: 'Email',
                hint: 'email@contoh.com',
                icon: Icons.email_outlined,
                controller: _email),
            const SizedBox(height: 18),
            AppTextField(
                label: 'No. Handphone',
                hint: '08xxxxxxxxxx',
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
                              title: const Text('Syarat dan Kebijakan Privasi'),
                              content: const SingleChildScrollView(
                                child: Text(
                                    'Dengan menggunakan A&A Transport, pengguna menyetujui pemrosesan data akun, data penyewa, dan data booking untuk keperluan reservasi serta pembayaran melalui Supabase dan SakuRupiah. Nomor kartu dan kredensial pembayaran tidak disimpan oleh aplikasi. Booking dianggap terkonfirmasi setelah pembayaran berstatus berhasil. Ketersediaan mobil mengikuti kapasitas armada dan masa sewa yang tercatat di sistem.'),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tutup')),
                              ],
                            ),
                          ),
                      child: const Text(
                          'Saya setuju dengan Syarat dan Kebijakan Privasi',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline)))),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(
                text: _loading ? 'Memproses...' : 'Register',
                onPressed: _loading ? null : _register),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Already have an account? Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
