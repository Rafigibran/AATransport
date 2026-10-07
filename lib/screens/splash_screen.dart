import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'H',
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                TextSpan(
                    text: 'ipo',
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
            ),
            const SizedBox(height: 6),
            const Text('Check-in to comfort',
                style:
                    TextStyle(color: AppColors.textGrey, letterSpacing: 1.2)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
