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
            const Icon(Icons.directions_car,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'A&A',
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                TextSpan(
                    text: ' Transport',
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
            ),
            const SizedBox(height: 6),
            const Text('Travel in comfort',
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
