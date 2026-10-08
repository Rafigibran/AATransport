import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final pages = const [
    _PageData(
      image:
          'https://images.unsplash.com/photo-1503376780353-3e669a7b70b9?w=900&q=80',
      title: 'Temukan Mobil Sewa\nTerbaik Untukmu',
      desc:
          'Berbagai pilihan mobil bersih dan terawat untuk perjalanan bisnis, keluarga, dan liburan.',
    ),
    _PageData(
      image:
          'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
      title: 'Booking Mobil Impianmu\nHanya Sekali Ketuk',
      desc:
          'Pilih tanggal, tentukan layanan dengan sopir atau lepas kunci, dan bayar dengan aman.',
    ),
    _PageData(
      image:
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=900&q=80',
      title: 'Jalan Nyaman dan Tenang\nbersama A&A Transport',
      desc:
          'Mobil siap jalan, harga transparan dalam Rupiah, dan dukungan pembayaran SakuRupiah.',
    ),
  ];

  void _next() {
    if (_index == pages.length - 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(p.image,
                              height: 380,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  height: 380,
                                  color: AppColors.background,
                                  child: const Icon(Icons.directions_car,
                                      size: 80, color: AppColors.primary))),
                        ),
                        const SizedBox(height: 28),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.25)),
                        const SizedBox(height: 12),
                        Text(p.desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textGrey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: i == _index
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(99)),
                            )),
                  ),
                  const SizedBox(height: 22),
                  if (isLast) ...[
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text('Register'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text('Already have an account? Log In'),
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                            child: const Text('Skip',
                                style: TextStyle(color: AppColors.textGrey))),
                        FloatingActionButton(
                            onPressed: _next,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.arrow_forward)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String image;
  final String title;
  final String desc;
  const _PageData(
      {required this.image, required this.title, required this.desc});
}
