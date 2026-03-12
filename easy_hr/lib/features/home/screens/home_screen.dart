import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _present = 0;
  int _absent = 0;
  int _late = 0;
  int _onLeave = 0;
  String? _myStatus;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAnnouncements();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiServiceProvider);
      // Load my today status
      final status = await api.getMyAttendanceStatus();
      if (mounted) {
        setState(() {
          _myStatus = status['status']?.toString();
        });
      }
      // Load daily report for admins
      final user = ref.read(authProvider).user;
      if (user?.isAdmin ?? false) {
        final report = await api.getDailyReport();
        if (mounted && report['summary'] != null) {
          final s = report['summary'];
          setState(() {
            _present = s['present'] ?? 0;
            _absent = s['absent'] ?? 0;
            _late = s['late'] ?? 0;
            _onLeave = s['on_leave'] ?? 0;
          });
        }
      } else {
        // For regular employees, show their own status
        if (mounted) {
          setState(() {
            _present = (_myStatus == 'present') ? 1 : 0;
            _absent = (_myStatus == 'absent' || _myStatus == 'not_checked_in') ? 1 : 0;
            _late = (_myStatus == 'late') ? 1 : 0;
            _onLeave = (_myStatus == 'on_leave') ? 1 : 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadAnnouncements() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(data).take(3).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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

              const SizedBox(height: 16),

              // Subscription Trial Banner
              _TrialBanner(ref: ref, mm: mm),

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
                _buildStatCard(context, isDark, s['present'] ?? 'Present', '$_present', AppColors.present, Iconsax.tick_circle),
                const SizedBox(width: 12),
                _buildStatCard(context, isDark, s['absent'] ?? 'Absent', '$_absent', AppColors.absent, Iconsax.close_circle),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _buildStatCard(context, isDark, s['late'] ?? 'Late', '$_late', AppColors.late_, Iconsax.clock),
                const SizedBox(width: 12),
                _buildStatCard(context, isDark, s['on_leave'] ?? 'On Leave', '$_onLeave', AppColors.onLeave, Iconsax.calendar_1),
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
                  _buildQuickAction(context, Iconsax.gps, mm ? 'တက်ရောက်မှု' : 'Attendance', AppColors.primary, () => context.go('/attendance')),
                  _buildQuickAction(context, Iconsax.calendar_add, s['leave'] ?? 'Leave', AppColors.onLeave, () => context.go('/leave')),
                  _buildQuickAction(context, Iconsax.notification_bing, mm ? 'ကြေညာ' : 'Announce', AppColors.error, () => context.push('/announcements')),
                  _buildQuickAction(context, Iconsax.money_send, s['payroll'] ?? 'Payroll', AppColors.accent, () => context.go('/payroll')),
                  if (user?.isAdmin ?? false) ...[
                    _buildQuickAction(context, Iconsax.people5, mm ? 'ဝန်ထမ်း' : 'Employees', AppColors.warning, () => context.push('/admin/employees')),
                    _buildQuickAction(context, Iconsax.chart_square, s['reports'] ?? 'Reports', AppColors.info, () => context.push('/admin/attendance-report')),
                    _buildQuickAction(context, Iconsax.user_add, s['add_staff'] ?? 'Add Staff', AppColors.primary, () => context.push('/admin/employees/add')),
                    _buildQuickAction(context, Iconsax.setting_2, s['settings'] ?? 'Settings', AppColors.lightTextSecondary, () => context.push('/settings/company')),
                  ],
                  _buildQuickAction(context, Iconsax.receipt_2, mm ? 'အစီအစဉ်' : 'Plans', Colors.teal, () => context.push('/billing')),
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
              if (_announcements.isEmpty)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                  ),
                  child: Center(child: Text(mm ? 'ကြေညာချက် မရှိသေးပါ' : 'No announcements yet',
                    style: Theme.of(context).textTheme.bodySmall)),
                ),
              ..._announcements.map((a) {
                final isHigh = a['priority'] == 'high';
                final isRead = a['is_read'] == true;
                final title = a['title']?.toString() ?? '';
                final content = a['content']?.toString() ?? '';
                final borderColor = isHigh ? AppColors.error.withOpacity(0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
                return GestureDetector(
                  onTap: () => context.push('/announcements'),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isHigh ? AppColors.error.withOpacity(0.05) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: isHigh ? 1.5 : 0.5),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: (isHigh ? AppColors.error : AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(isHigh ? Iconsax.flag : Iconsax.message_text, color: isHigh ? AppColors.error : AppColors.primary, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(content, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ]),
                  ),
                );
              }),

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

class _TrialBanner extends StatelessWidget {
  final WidgetRef ref;
  final bool mm;
  const _TrialBanner({required this.ref, required this.mm});

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(authProvider).subscription;
    if (sub == null) return const SizedBox.shrink();

    // Show banner for: expired, expiring soon (<=7 days), or free plan
    if (sub.isExpired) {
      return _buildBanner(
        context,
        color: AppColors.error,
        icon: Iconsax.warning_2,
        title: mm ? 'သက်တမ်းကုန်ဆုံးသွားပါပြီ' : 'Subscription Expired',
        subtitle: mm ? 'ဆက်လက်အသုံးပြုရန် အဆင့်မြှင့်ပါ' : 'Upgrade to continue using all features',
      );
    }

    if (sub.isTrialExpiringSoon) {
      return _buildBanner(
        context,
        color: AppColors.warning,
        icon: Iconsax.clock,
        title: mm ? 'Trial ${sub.daysRemaining} ရက် ကျန်ပါသေးသည်' : '${sub.daysRemaining} days left in trial',
        subtitle: mm ? 'အစီအစဉ် ရွေးချယ်ပြီး ဆက်သုံးပါ' : 'Choose a plan to keep access',
      );
    }

    if (sub.isFree && sub.daysRemaining > 7) {
      return _buildBanner(
        context,
        color: AppColors.present,
        icon: Iconsax.gift,
        title: mm ? 'Free Trial - ${sub.daysRemaining} ရက်ကျန်' : 'Free Trial - ${sub.daysRemaining} days left',
        subtitle: mm ? '၃၀ ရက် အခမဲ့ သုံးနိုင်ပါသည်' : 'Enjoy 30 days free access',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner(BuildContext context, {required Color color, required IconData icon, required String title, required String subtitle}) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/billing'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}