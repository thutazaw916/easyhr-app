import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../settings/screens/notification_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final lang = ref.watch(languageProvider);
    final darkMode = ref.watch(darkModeProvider);
    final s = AppStrings.get(lang);
    final mm = lang == 'mm';
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user?.profilePhotoUrl != null ? NetworkImage(user!.profilePhotoUrl!) : null,
                child: user?.profilePhotoUrl == null
                    ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? 'User', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(user?.email ?? user?.phone ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(user?.role?.replaceAll('_', ' ').toUpperCase() ?? 'EMPLOYEE',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(user?.companyName ?? '', style: Theme.of(context).textTheme.bodySmall),

              const SizedBox(height: 28),

              // Language Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    _langBtn(ref, 'mm', '🇲🇲 မြန်မာ', lang == 'mm', isDark),
                    _langBtn(ref, 'en', '🇬🇧 English', lang == 'en', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // General Settings
              _tile(context, isDark, Iconsax.user_edit, s['edit_profile'] ?? 'Edit Profile', null,
                () => _showEditProfileSheet(context, ref, isDark, mm)),
              _tile(context, isDark, Iconsax.moon, s['dark_mode'] ?? 'Dark Mode', null, () {
                ref.read(darkModeProvider.notifier).state = !darkMode;
              }, trailing: Switch(value: darkMode, activeColor: AppColors.primary, onChanged: (v) => ref.read(darkModeProvider.notifier).state = v)),
              _tile(context, isDark, Iconsax.notification, s['notifications'] ?? 'Notifications', null,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),

              // Admin Settings
              if (isAdmin) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(mm ? 'ကုမ္ပဏီ စီမံခန့်ခွဲမှု' : 'Company Management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                _tile(context, isDark, Iconsax.clock, s['work_hours'] ?? 'Work Hours',
                  mm ? 'အလုပ်ချိန်/ဆင်းချိန် သတ်မှတ်ရန်' : 'Set work start/end time',
                  () => context.push('/settings/company')),
                _tile(context, isDark, Iconsax.calendar_tick, s['leave_settings'] ?? 'Leave Settings',
                  mm ? 'ခွင့်အမျိုးအစားများ သတ်မှတ်ရန်' : 'Configure leave types & days',
                  () => context.push('/settings/company')),
                _tile(context, isDark, Iconsax.building, mm ? 'ရုံးခွဲများ' : 'Branches',
                  mm ? 'ရုံးခွဲတည်နေရာ စီမံရန်' : 'Manage office locations',
                  () => context.push('/settings/branches')),
                _tile(context, isDark, Iconsax.hierarchy_square_2, mm ? 'ဌာနများ' : 'Departments',
                  mm ? 'ဌာနများ စီမံရန်' : 'Organize teams',
                  () => context.push('/settings/departments')),
                _tile(context, isDark, Iconsax.card, mm ? 'အစီအစဉ်နှင့် ငွေပေးချေမှု' : 'Plans & Billing',
                  mm ? 'လစဉ်ကြေး စီမံရန်' : 'Manage subscription',
                  () => context.push('/billing')),
              ],

              const SizedBox(height: 16),
              _tile(context, isDark, Iconsax.info_circle, s['about'] ?? 'About', 'Easy HR v1.0.0',
                () => context.push('/about')),

              const SizedBox(height: 16),

              // Logout
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.logout, size: 20, color: AppColors.absent),
                  label: Text(s['logout'] ?? 'Logout', style: const TextStyle(color: AppColors.absent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.absent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showLogoutDialog(context, ref, mm),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EDIT PROFILE BOTTOM SHEET ====================
  void _showEditProfileSheet(BuildContext context, WidgetRef ref, bool isDark, bool mm) {
    final user = ref.read(authProvider).user;
    final nameC = TextEditingController(text: user?.name ?? '');
    final phoneC = TextEditingController(text: user?.phone ?? '');
    final emailC = TextEditingController(text: user?.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(mm ? '✏️ ပရိုဖိုင်ပြင်ဆင်ရန်' : '✏️ Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: mm ? 'အမည်' : 'Name',
                  prefixIcon: const Icon(Iconsax.user, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: mm ? 'ဖုန်းနံပါတ်' : 'Phone',
                  prefixIcon: const Icon(Iconsax.call, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: mm ? 'အီးမေးလ်' : 'Email',
                  prefixIcon: const Icon(Iconsax.sms, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.tick_circle, size: 20),
                  label: Text(mm ? 'သိမ်းဆည်းရန်' : 'Save Changes',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(mm ? '✅ ပရိုဖိုင် သိမ်းပြီး!' : '✅ Profile updated!'),
                      backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langBtn(WidgetRef ref, String code, String label, bool active, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(languageProvider.notifier).state = code,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            )),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, bool isDark, IconData icon, String title, String? subtitle, VoidCallback onTap, {Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null) Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            trailing ?? Icon(Iconsax.arrow_right_3, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool mm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(mm ? 'ထွက်ရန်' : 'Logout'),
        content: Text(mm ? 'ထွက်ရန် သေချာပါသလား?' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mm ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(mm ? 'ထွက်ရန်' : 'Logout'),
          ),
        ],
      ),
    );
  }
}