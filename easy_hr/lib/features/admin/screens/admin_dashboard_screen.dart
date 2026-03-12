import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _totalEmployees = 0;
  int _present = 0;
  int _absent = 0;
  int _late = 0;
  int _onLeave = 0;
  double _totalOtHours = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _notCheckedIn = [];
  List<Map<String, dynamic>> _checkedInRecords = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final api = ref.read(apiServiceProvider);
      final report = await api.getDailyReport();
      debugPrint('[AdminDash] report: $report');
      if (mounted) {
        final summary = report['summary'] ?? {};
        setState(() {
          _totalEmployees = summary['total_employees'] ?? 0;
          _present = summary['present'] ?? 0;
          _absent = summary['absent'] ?? 0;
          _late = summary['late'] ?? 0;
          _onLeave = summary['on_leave'] ?? 0;
          _notCheckedIn = List<Map<String, dynamic>>.from(report['not_checked_in'] ?? []);
          _checkedInRecords = List<Map<String, dynamic>>.from(report['records'] ?? []);
          _loading = false;
        });
      }
      // Load monthly OT
      final history = await api.getMyAttendanceHistory();
      if (mounted && history['summary'] != null) {
        setState(() {
          _totalOtHours = (history['summary']['total_overtime_hours'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('[AdminDash] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final int total = _totalEmployees > 0 ? _totalEmployees : 1;
    final double avgRate = total > 0 ? ((_present + _late) / total * 100) : 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Iconsax.export_1), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      _buildHeaderStat('Employees', '$_totalEmployees', Iconsax.people5),
                      const SizedBox(width: 24),
                      _buildHeaderStat('Avg Rate', '${avgRate.round()}%', Iconsax.chart_square),
                      const SizedBox(width: 24),
                      _buildHeaderStat('OT Hours', '${_totalOtHours.round()}', Iconsax.timer_1),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Today's Attendance
            Text("Today's Attendance", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else ...[
              Row(children: [
                _buildStatCard(context, isDark, 'Present', '$_present', AppColors.present, Iconsax.tick_circle, '${total > 0 ? (_present / total * 100).round() : 0}%'),
                const SizedBox(width: 10),
                _buildStatCard(context, isDark, 'Absent', '$_absent', AppColors.absent, Iconsax.close_circle, '${total > 0 ? (_absent / total * 100).round() : 0}%'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _buildStatCard(context, isDark, 'Late', '$_late', AppColors.late_, Iconsax.clock, '${total > 0 ? (_late / total * 100).round() : 0}%'),
                const SizedBox(width: 10),
                _buildStatCard(context, isDark, 'On Leave', '$_onLeave', AppColors.onLeave, Iconsax.calendar_1, '${total > 0 ? (_onLeave / total * 100).round() : 0}%'),
              ]),
            ],

            const SizedBox(height: 20),

            // Checked In Today (real employee records)
            if (_checkedInRecords.isNotEmpty) ...[
              Text('Checked In Today (${_checkedInRecords.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._checkedInRecords.map((record) {
                final emp = record['employee'];
                String name = 'Employee';
                if (emp is Map<String, dynamic>) {
                  final fn = emp['first_name'] ?? '';
                  final ln = emp['last_name'] ?? '';
                  name = '$fn $ln'.trim();
                  if (name.isEmpty) name = emp['name_mm'] ?? emp['employee_code'] ?? 'Employee';
                }
                final status = record['status'] ?? 'present';
                final isLate = status == 'late';
                final lateMin = record['late_minutes'] ?? 0;
                final hasCheckout = record['check_out_time'] != null;
                final totalH = (record['total_hours'] ?? 0).toDouble();

                // Format times
                String ciStr = '--:--';
                if (record['check_in_time'] != null) {
                  final ci = DateTime.tryParse(record['check_in_time'].toString());
                  if (ci != null) ciStr = DateFormat('h:mm a').format(ci.toLocal());
                }
                String coStr = 'Working...';
                if (hasCheckout) {
                  final co = DateTime.tryParse(record['check_out_time'].toString());
                  if (co != null) coStr = DateFormat('h:mm a').format(co.toLocal());
                }
                String hoursStr = '';
                if (hasCheckout && totalH > 0) {
                  hoursStr = '${totalH.floor()}h ${((totalH - totalH.floor()) * 60).round()}m';
                }

                final Color sc = isLate ? AppColors.late_ : AppColors.present;
                final IconData si = isLate ? Iconsax.clock : Iconsax.tick_circle;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(si, color: sc, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            'In: $ciStr • ${hasCheckout ? 'Out: $coStr' : coStr}${hoursStr.isNotEmpty ? ' • $hoursStr' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isLate ? 'LATE ${lateMin}m' : 'PRESENT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Not Checked In Today
            if (_notCheckedIn.isNotEmpty) ...[
              Text('Not Checked In Yet (${_notCheckedIn.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._notCheckedIn.map((emp) {
                final fn = emp['first_name'] ?? '';
                final ln = emp['last_name'] ?? '';
                final name = '$fn $ln'.trim();
                final code = emp['employee_code'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.absent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.absent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Iconsax.close_circle, color: AppColors.absent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isNotEmpty ? name : 'Employee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          if (code.isNotEmpty) Text(code, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.absent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('ABSENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.absent)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Quick Admin Actions
            Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildActionTile(context, isDark, Iconsax.user_add, 'Add Employee', 'Register new staff', AppColors.primary, () => context.push('/admin/employees/add')),
            _buildActionTile(context, isDark, Iconsax.people5, 'Employee List', 'View & manage all staff', AppColors.accent, () => context.push('/admin/employees')),
            _buildActionTile(context, isDark, Iconsax.document_text, 'Attendance Report', 'Daily & monthly reports', AppColors.info, () => context.push('/admin/attendance-report')),

            const SizedBox(height: 40),
          ],
        ),
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

}