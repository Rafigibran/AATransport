import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../onboarding_screen.dart';
import 'info_screen.dart';
import '../booking/review_summary_screen.dart' show kWhatsAppNumber;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future = ProfileService.fetchProfile();

  void _reload() => setState(() => _future = ProfileService.fetchProfile());

  void _openInfo(BuildContext context, String title,
      List<({String heading, String body})> sections) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfoScreen(title: title, sections: sections),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/$kWhatsAppNumber');
    final opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showErrorSnackBar(context, tr('rs_wa_fail'));
    }
  }

  Future<void> _openPricingSettings(BuildContext context) async {
    final settings = await SettingsService.fetchSettings(forceRefresh: true);
    if (!context.mounted) return;
    final t = settings.taxPercent % 1 == 0
        ? settings.taxPercent.toStringAsFixed(0)
        : settings.taxPercent.toStringAsFixed(2);
    final f = settings.feePercent % 1 == 0
        ? settings.feePercent.toStringAsFixed(0)
        : settings.feePercent.toStringAsFixed(2);
    _openInfo(
      context,
      tr('pf_settings'),
      [
        (
          heading: tr('pf_taxfee_title'),
          body: tr('pf_taxfee_body', {'t': t, 'f': f}),
        ),
        (
          heading: tr('pf_notif_title'),
          body: tr('pf_notif_body'),
        ),
      ],
    );
  }

  Future<void> _editProfile(Map<String, dynamic>? profile) async {
    final name =
        TextEditingController(text: (profile?['full_name'] ?? '').toString());
    final phone =
        TextEditingController(text: (profile?['phone'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('pf_edit_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration:
                    InputDecoration(labelText: tr('pf_name_full'))),
            const SizedBox(height: 12),
            TextField(
                controller: phone,
                decoration: InputDecoration(labelText: tr('pf_phone'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('common_cancel'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('common_save'))),
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
      appBar: AppBar(title: Text(tr('pf_title'))),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
                message: tr('pf_profile_fail'), onRetry: _reload);
          }
          final profile = snapshot.data;
          final name = (profile?['full_name'] ?? tr('pf_guest')).toString();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                    radius: 40,
                    backgroundImage: (profile?['avatar_url'] ?? '')
                            .toString()
                            .isNotEmpty
                        ? NetworkImage(profile!['avatar_url'].toString())
                        : null,
                    child: (profile?['avatar_url'] ?? '').toString().isEmpty
                        ? const Icon(Icons.person, size: 38)
                        : null),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 12),
                TextButton.icon(
                    onPressed: () => _editProfile(profile),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(tr('pf_edit'))),
                const SizedBox(height: 14),
                _tile(Icons.chat_outlined, tr('pf_whatsapp'),
                    trailing: '0858-6370-1489',
                    onTap: () => _openWhatsApp(context)),
                _tile(Icons.attach_money, tr('pf_currency'),
                    trailing:
                        AppStrings.isEnglish ? 'USD (\$)' : 'IDR (Rupiah)',
                    onTap: () => _openInfo(
                        context,
                        tr('pf_currency'),
                        [
                          (
                            heading: tr('pf_currency'),
                            body: tr('pf_currency_body'),
                          ),
                        ])),
                _tile(Icons.language_outlined, tr('pf_lang'),
                    trailing:
                        AppStrings.isEnglish ? 'English' : 'Indonesia',
                    onTap: () => _openInfo(
                        context,
                        tr('pf_lang'),
                        [
                          (
                            heading: tr('pf_lang'),
                            body: tr('pf_lang_body'),
                          ),
                        ])),
                _tile(Icons.help_outline, tr('pf_help'),
                    onTap: () => _openInfo(
                        context,
                        tr('pf_help'),
                        [
                          (
                            heading: tr('pf_help_wa_title'),
                            body: tr('pf_help_wa_body'),
                          ),
                          (
                            heading: tr('pf_help_change_title'),
                            body: tr('pf_help_change_body'),
                          ),
                          (
                            heading: tr('pf_help_nodata_title'),
                            body: tr('pf_help_nodata_body'),
                          ),
                        ])),
                _tile(Icons.question_answer_outlined, tr('pf_faq'),
                    onTap: () => _openInfo(
                        context,
                        tr('pf_faq'),
                        [
                          (
                            heading: tr('pf_faq_tax_title'),
                            body: tr('pf_faq_tax_body'),
                          ),
                          (
                            heading: tr('pf_faq_pay_title'),
                            body: tr('pf_faq_pay_body'),
                          ),
                          (
                            heading: tr('pf_faq_confirm_title'),
                            body: tr('pf_faq_confirm_body'),
                          ),
                        ])),
                _tile(Icons.settings_outlined, tr('pf_settings'),
                    onTap: () => _openPricingSettings(context)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(tr('pf_logout'),
                        style: const TextStyle(
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
          Text(tr('pf_logout_title'),
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          PrimaryButton(
            text: tr('pf_logout'),
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
              text: tr('common_cancel'),
              isOutline: true,
              onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
