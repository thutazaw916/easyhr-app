import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _todayStats = {'present': 42, 'absent': 3, 'late': 5, 'on_leave': 8, 'total': 58};
  final _monthlyStats = {'total_working_days': 22, 'avg_attendance': 91.5, 'total_ot_hours': 156, 'pending_leaves': 4};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Iconsax.export_1), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.companyName ?? 'Company', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${DateFormat('MMMM yyyy').format(DateTime.now())} Report', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeaderStat('Employees', '${_todayStats['total']}', Iconsax.people5),
                      const SizedBox(width: 24),
                      _buildHeaderStat('Avg Rate', '${_monthlyStats['avg_attendance']}%', Iconsax.chart_square),
                      const SizedBox(width: 24),
                      _buildHeaderStat('OT Hours', '${_monthlyStats['total_ot_hours']}', Iconsax.timer_1),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Today's Attendance
            Text("Today's Attendance", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              _buildStatCard(context, isDark, 'Present', '${_todayStats['present']}', AppColors.present, Iconsax.tick_circle, '${((_todayStats['present']! / _todayStats['total']!) * 100).round()}%'),
              const SizedBox(width: 10),
              _buildStatCard(context, isDark, 'Absent', '${_todayStats['absent']}', AppColors.absent, Iconsax.close_circle, '${((_todayStats['absent']! / _todayStats['total']!) * 100).round()}%'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _buildStatCard(context, isDark, 'Late', '${_todayStats['late']}', AppColors.late_, Iconsax.clock, '${((_todayStats['late']! / _todayStats['total']!) * 100).round()}%'),
              const SizedBox(width: 10),
              _buildStatCard(context, isDark, 'On Leave', '${_todayStats['on_leave']}', AppColors.onLeave, Iconsax.calendar_1, '${((_todayStats['on_leave']! / _todayStats['total']!) * 100).round()}%'),
            ]),

            const SizedBox(height: 20),

            // Weekly Chart
            Text('Weekly Attendance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(context, 'Mon', 0.92, AppColors.present),
                      _buildBar(context, 'Tue', 0.88, AppColors.present),
                      _buildBar(context, 'Wed', 0.95, AppColors.present),
                      _buildBar(context, 'Thu', 0.85, AppColors.warning),
                      _buildBar(context, 'Fri', 0.78, AppColors.warning),
                      _buildBar(context, 'Sat', 0.0, AppColors.lightDivider),
                      _buildBar(context, 'Sun', 0.0, AppColors.lightDivider),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(AppColors.present, 'Good (>85%)'),
                      const SizedBox(width: 16),
                      _buildLegend(AppColors.warning, 'Warning (<85%)'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Admin Actions — only 3 items
            Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildActionTile(context, isDark, Iconsax.user_add, 'Add Employee', 'Register new staff', AppColors.primary, () => context.push('/admin/employees/add')),
            _buildActionTile(context, isDark, Iconsax.people5, 'Employee List', 'View & manage all staff', AppColors.accent, () => context.push('/admin/employees')),
            _buildActionTile(context, isDark, Iconsax.document_text, 'Attendance Report', 'Daily & monthly reports', AppColors.info, () => context.push('/admin/attendance-report')),

            const SizedBox(height: 24),

            // Department Summary
            Text('Department Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildDeptRow(context, isDark, 'Engineering', 15, 14, 1),
            _buildDeptRow(context, isDark, 'Sales', 12, 10, 2),
            _buildDeptRow(context, isDark, 'HR', 5, 5, 0),
            _buildDeptRow(context, isDark, 'Marketing', 8, 7, 1),
            _buildDeptRow(context, isDark, 'Operations', 18, 16, 2),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, bool isDark, String label, String value, Color color, IconData icon, String percent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text('$label ($percent)', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, String day, double value, Color color) {
    return Column(
      children: [
        Text('${(value * 100).round()}%', style: TextStyle(fontSize: 10, color: value > 0 ? color : Colors.transparent)),
        const SizedBox(height: 4),
        Container(
          width: 32, height: value > 0 ? 100 * value : 4,
          decoration: BoxDecoration(color: color.withOpacity(value > 0 ? 0.8 : 0.2), borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(day, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }

  Widget _buildActionTile(BuildContext context, bool isDark, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
            Icon(Iconsax.arrow_right_3, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptRow(BuildContext context, bool isDark, String name, int total, int present, int absent) {
    final rate = total > 0 ? (present / total * 100) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14))),
          Text('$present/$total', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate / 100, minHeight: 6,
                backgroundColor: AppColors.absent.withOpacity(0.2),
                color: rate >= 90 ? AppColors.present : rate >= 80 ? AppColors.warning : AppColors.absent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${rate.round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: rate >= 90 ? AppColors.present : rate >= 80 ? AppColors.warning : AppColors.absent)),
        ],
      ),
    );
  }
}