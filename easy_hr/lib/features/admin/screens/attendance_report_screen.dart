import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dailyReport = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDailyReport();
  }

  Future<void> _loadDailyReport() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await api.getDailyReport(date: dateStr);
      setState(() {
        _dailyReport = List<Map<String, dynamic>>.from(result['records'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dailyReport = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: const Text('Attendance Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Iconsax.calendar_1, size: 18)),
            Tab(text: 'Monthly', icon: Icon(Iconsax.chart_square, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(isDark),
          _buildMonthlyTab(isDark),
        ],
      ),
    );
  }

  Widget _buildDailyTab(bool isDark) {
    final summary = _calculateSummary();

    return Column(
      children: [
        // Date Picker
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left_2, size: 20),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  _loadDailyReport();
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadDailyReport();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.calendar, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.arrow_right_3, size: 20),
                onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                    ? () {
                        setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                        _loadDailyReport();
                      }
                    : null,
              ),
            ],
          ),
        ),

        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildMiniStat(isDark, 'Present', '${summary['present']}', AppColors.present),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Late', '${summary['late']}', AppColors.late_),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Absent', '${summary['absent']}', AppColors.absent),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Leave', '${summary['on_leave']}', AppColors.onLeave),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Records
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _dailyReport.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.document_text, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        const SizedBox(height: 12),
                        Text('No attendance records', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _dailyReport.length,
                      itemBuilder: (context, index) => _buildRecordCard(isDark, _dailyReport[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTab(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Iconsax.chart_21, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Monthly Report', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Monthly attendance summary with charts, department breakdowns, and exportable PDF reports.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_download, size: 18),
              label: const Text('Export PDF'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📊 Export feature coming soon!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateSummary() {
    int present = 0, late = 0, absent = 0, onLeave = 0;
    for (var r in _dailyReport) {
      switch (r['status']) {
        case 'present': present++; break;
        case 'late': late++; break;
        case 'absent': absent++; break;
        case 'on_leave': onLeave++; break;
      }
    }
    return {'present': present, 'late': late, 'absent': absent, 'on_leave': onLeave};
  }

  Widget _buildMiniStat(bool isDark, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(bool isDark, Map<String, dynamic> record) {
    final name = record['employee_name'] ?? 'Unknown';
    final status = record['status'] ?? 'absent';
    final checkIn = record['check_in_time'];
    final checkOut = record['check_out_time'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'present': statusColor = AppColors.present; statusIcon = Iconsax.tick_circle; break;
      case 'late': statusColor = AppColors.late_; statusIcon = Iconsax.clock; break;
      case 'on_leave': statusColor = AppColors.onLeave; statusIcon = Iconsax.calendar_1; break;
      default: statusColor = AppColors.absent; statusIcon = Iconsax.close_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (checkIn != null) Text('In: $checkIn ${checkOut != null ? '• Out: $checkOut' : ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}