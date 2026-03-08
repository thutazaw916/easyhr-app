import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final s = AppStrings.get(lang);
    final mm = lang == 'mm';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(s), style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const SizedBox(height: 4),
                        Text(user?.name ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/announcements'),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Iconsax.notification, size: 22)),
                          Positioned(right: 10, top: 10,
                            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text('${user?.companyName ?? ''} \u2022 ${user?.role?.replaceAll('_', ' ').toUpperCase() ?? ''}',
                style: Theme.of(context).textTheme.bodySmall),

              const SizedBox(height: 24),

              // Date Card → Myanmar Calendar
              GestureDetector(
                onTap: () => context.push('/calendar'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('EEEE').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(DateFormat('hh:mm a').format(DateTime.now()), style: const TextStyle(color: Colors.white60, fontSize: 16)),
                          ],
                        ),
                      ),
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Iconsax.calendar_1, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Admin Dashboard Card (only for admin)
              if (user?.isAdmin ?? false)
                GestureDetector(
                  onTap: () => context.push('/admin/dashboard'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Iconsax.chart_square, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['admin_dashboard'] ?? 'Admin Dashboard', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(s['admin_dashboard_desc'] ?? 'KPI, Reports, Employee Management', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.arrow_right_3, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                ),

              // Today's Summary
              Text(s['todays_status'] ?? "Today's Status", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(children: [
                _buildStatCard(context, isDark, s['present'] ?? 'Present', '0', AppColors.present, Iconsax.tick_circle),
                const SizedBox(width: 12),
                _buildStatCard(context, isDark, s['absent'] ?? 'Absent', '0', AppColors.absent, Iconsax.close_circle),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _buildStatCard(context, isDark, s['late'] ?? 'Late', '0', AppColors.late_, Iconsax.clock),
                const SizedBox(width: 12),
                _buildStatCard(context, isDark, s['on_leave'] ?? 'On Leave', '0', AppColors.onLeave, Iconsax.calendar_1),
              ]),

              const SizedBox(height: 24),

              // Quick Actions
              Text(s['quick_actions'] ?? 'Quick Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12, crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildQuickAction(context, Iconsax.scan_barcode, s['qr_scan'] ?? 'QR Scan', AppColors.primary, () => context.go('/attendance')),
                  _buildQuickAction(context, Iconsax.calendar_add, s['leave'] ?? 'Leave', AppColors.onLeave, () => context.go('/leave')),
                  _buildQuickAction(context, Iconsax.message, s['chat'] ?? 'Chat', AppColors.accent, () => context.push('/chat')),
                  _buildQuickAction(context, Iconsax.cpu, mm ? 'AI အကူ' : 'AI Help', AppColors.info, () => context.push('/chatbot')),
                  if (user?.isAdmin ?? false) ...[
                    _buildQuickAction(context, Iconsax.people5, mm ? 'ဝန်ထမ်း' : 'Employees', AppColors.warning, () => context.push('/admin/employees')),
                    _buildQuickAction(context, Iconsax.chart_square, s['reports'] ?? 'Reports', AppColors.info, () => context.push('/admin/attendance-report')),
                    _buildQuickAction(context, Iconsax.user_add, s['add_staff'] ?? 'Add Staff', AppColors.primary, () => context.push('/admin/employees/add')),
                    _buildQuickAction(context, Iconsax.money_send, s['payroll'] ?? 'Payroll', AppColors.accent, () => context.go('/payroll')),
                    _buildQuickAction(context, Iconsax.setting_2, s['settings'] ?? 'Settings', AppColors.lightTextSecondary, () => context.push('/settings/company')),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Announcements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['announce'] ?? 'Announcements', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(onPressed: () => context.push('/announcements'), child: Text(s['view_all'] ?? 'View All')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Iconsax.flag, color: AppColors.error, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mm ? 'ရုံးပိတ်ရက် - သင်္ကြန်' : 'Office Closure - Thingyan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                    Text(mm ? 'ဧပြီ ၁၃-၁၇ ရုံးပိတ်ပါမည်' : 'April 13-17 closed for holiday', style: Theme.of(context).textTheme.bodySmall),
                  ])),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ]),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, bool isDark, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  String _getGreeting(Map<String, String> s) {
    final hour = DateTime.now().hour;
    if (hour < 12) return s['good_morning'] ?? 'Good Morning';
    if (hour < 17) return s['good_afternoon'] ?? 'Good Afternoon';
    return s['good_evening'] ?? 'Good Evening';
  }
}