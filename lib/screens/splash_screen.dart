import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'home/main_screen.dart';

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
      bool loggedIn = false;
      try {
        loggedIn = Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        loggedIn = false;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                loggedIn ? const MainScreen() : const OnboardingScreen()),
      );
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
            // Logo final "Berbagi": lockup bertumpuk dari
            // branding/logo-design/final (simbol AA + wordmark + tagline).
            Image.asset(
              'assets/images/logo-stacked.png',
              width: 272,
              fit: BoxFit.contain,
              semanticLabel: 'A&A Transport',
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
