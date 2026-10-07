import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const CircleAvatar(
              radius: 40,
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?img=12')),
          const SizedBox(height: 12),
          const Text('Alul Ahmad',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const Text('alalahmad03@gmail.com',
              style: TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 26),
          _tile(Icons.payment_outlined, 'Payment Methods'),
          _tile(Icons.attach_money, 'Currency', trailing: 'USD'),
          _tile(Icons.language_outlined, 'Language', trailing: 'English'),
          _tile(Icons.help_outline, 'Help Center'),
          _tile(Icons.question_answer_outlined, 'FAQs'),
          _tile(Icons.settings_outlined, 'Settings'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () => _logoutDialog(context),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tile(IconData icon, String title, {String? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(color: AppColors.textGrey))
            : const Icon(Icons.chevron_right, color: AppColors.textGrey),
      ),
    );
  }

  void _logoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout, color: Colors.red, size: 34)),
          const SizedBox(height: 16),
          const Text('Are You Sure?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          PrimaryButton(
              text: 'Logout',
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (_) => false)),
          const SizedBox(height: 12),
          PrimaryButton(
              text: 'Cancel',
              isOutline: true,
              onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
