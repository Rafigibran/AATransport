import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_info_screen.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future = ProfileService.fetchProfile();

  void _reload() => setState(() => _future = ProfileService.fetchProfile());

  Future<void> _editProfile(Map<String, dynamic>? profile) async {
    final name =
        TextEditingController(text: (profile?['full_name'] ?? '').toString());
    final phone =
        TextEditingController(text: (profile?['phone'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama lengkap')),
            const SizedBox(height: 12),
            TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'No. handphone')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ProfileService.updateProfile(name: name.text, phone: phone.text);
        _reload();
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name =
              (profile?['full_name'] ?? 'Pengguna A&A Transport').toString();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 40, child: Icon(Icons.person, size: 38)),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 12),
                TextButton.icon(
                    onPressed: () => _editProfile(profile),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profil')),
                const SizedBox(height: 14),
                _tile(Icons.payments_outlined, 'Payment Methods',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const SavedPaymentMethodsScreen()))),
                _tile(Icons.attach_money, 'Currency', trailing: 'IDR (Rupiah)'),
                _tile(Icons.language_outlined, 'Language',
                    trailing: 'Indonesia'),
                _tile(Icons.help_outline, 'Help Center'),
                _tile(Icons.question_answer_outlined, 'FAQs'),
                _tile(Icons.settings_outlined, 'Settings'),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () => _logoutDialog(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title,
      {String? trailing, VoidCallback? onTap}) {
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
        onTap: onTap,
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
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (_) => false);
            },
          ),
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
