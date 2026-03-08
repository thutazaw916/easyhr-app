import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'အကြောင်း' : 'About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // App Logo
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Text('HR', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Easy HR', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(mm ? 'မြန်မာ့ HR စီမံခန့်ခွဲမှုစနစ်' : 'Myanmar HR Management System',
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('v1.0.0', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),

            const SizedBox(height: 32),

            // Features
            _buildSection(context, isDark, mm ? 'အင်္ဂါရပ်များ' : 'Features', Iconsax.star, [
              _featureItem(mm ? 'ဝန်ထမ်းတက်ရောက်မှု (GPS + QR)' : 'Attendance Tracking (GPS + QR)', Iconsax.location_tick, AppColors.present),
              _featureItem(mm ? 'လစာတွက်ချက်မှု' : 'Payroll Management', Iconsax.money_send, AppColors.accent),
              _featureItem(mm ? 'ခွင့်စီမံခန့်ခွဲမှု' : 'Leave Management', Iconsax.calendar_tick, AppColors.onLeave),
              _featureItem(mm ? 'ဝန်ထမ်းစီမံခန့်ခွဲမှု' : 'Employee Management', Iconsax.people, AppColors.info),
              _featureItem(mm ? 'ရုံးခွဲ/ဌာန စီမံခန့်ခွဲမှု' : 'Branch & Department Management', Iconsax.building, AppColors.warning),
              _featureItem(mm ? 'ချတ် & ကြေညာချက်' : 'Chat & Announcements', Iconsax.message, AppColors.primary),
              _featureItem(mm ? 'မြန်မာပြက္ခဒိန်' : 'Myanmar Calendar', Iconsax.calendar_1, AppColors.absent),
              _featureItem(mm ? 'မြန်မာ/အင်္ဂလိပ် ဘာသာစကား' : 'Myanmar/English Language', Iconsax.translate, AppColors.info),
            ]),

            const SizedBox(height: 20),

            // Contact
            _buildSection(context, isDark, mm ? 'ဆက်သွယ်ရန်' : 'Contact & Support', Iconsax.call, [
              _contactItem(isDark, Iconsax.sms, mm ? 'အီးမေးလ်' : 'Email', 'support@easyhr.com'),
              _contactItem(isDark, Iconsax.call, mm ? 'ဖုန်း' : 'Phone', '+95 9 123 456 789'),
              _contactItem(isDark, Iconsax.global, mm ? 'ဝက်ဘ်ဆိုက်' : 'Website', 'www.easyhr.com'),
            ]),

            const SizedBox(height: 20),

            // Tech Stack
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.code, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(mm ? 'နည်းပညာ' : 'Technology', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _techItem(isDark, 'Frontend', 'Flutter + Dart'),
                  _techItem(isDark, 'Backend', 'NestJS + TypeScript'),
                  _techItem(isDark, 'Database', 'Supabase (PostgreSQL)'),
                  _techItem(isDark, 'Auth', 'JWT + OTP'),
                  _techItem(isDark, 'State', 'Riverpod'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Legal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  _legalItem(isDark, mm, Iconsax.document_text, mm ? 'အသုံးပြုမှု စည်းကမ်းချက်' : 'Terms of Service'),
                  const SizedBox(height: 10),
                  _legalItem(isDark, mm, Iconsax.shield_tick, mm ? 'ကိုယ်ရေးအချက်အလက် မူဝါဒ' : 'Privacy Policy'),
                  const SizedBox(height: 10),
                  _legalItem(isDark, mm, Iconsax.document_code, mm ? 'လိုင်စင်' : 'Licenses'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(mm ? '© 2026 Easy HR. မူပိုင်ခွင့်ရယူထားသည်။' : '© 2026 Easy HR. All rights reserved.',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, bool isDark, String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _featureItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _contactItem(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _techItem(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _legalItem(bool isDark, bool mm, IconData icon, String text) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          Icon(Iconsax.arrow_right_3, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ],
      ),
    );
  }
}