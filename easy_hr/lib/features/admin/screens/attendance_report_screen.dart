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

  // Monthly report state
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _monthlyRecords = [];
  Map<String, dynamic> _monthlySummary = {};
  bool _monthlyLoading = false;

  Future<void> _loadMonthlyReport() async {
    setState(() => _monthlyLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getMyAttendanceHistory(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      setState(() {
        _monthlySummary = Map<String, dynamic>.from(result['summary'] ?? {});
        // Group daily data
        final records = List<Map<String, dynamic>>.from(result['records'] ?? []);
        _monthlyRecords = records;
        _monthlyLoading = false;
      });
    } catch (e) {
      debugPrint('[MonthlyReport] error: $e');
      setState(() => _monthlyLoading = false);
    }
  }

  Widget _buildMonthlyTab(bool isDark) {
    if (_monthlyRecords.isEmpty && !_monthlyLoading) {
      // Auto-load on first visit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthlyRecords.isEmpty && !_monthlyLoading) _loadMonthlyReport();
      });
    }

    final totalDays = _monthlySummary['total_working_days'] ?? 0;
    final presentDays = _monthlySummary['present_days'] ?? 0;
    final lateDays = _monthlySummary['late_days'] ?? 0;
    final absentDays = _monthlySummary['absent_days'] ?? 0;
    final leaveDays = _monthlySummary['leave_days'] ?? 0;
    final totalHours = (_monthlySummary['total_hours'] ?? 0).toDouble();
    final totalOt = (_monthlySummary['total_overtime_hours'] ?? 0).toDouble();

    return Column(
      children: [
        // Month picker
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left_2, size: 20),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
                  _loadMonthlyReport();
                },
              ),
              Expanded(
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
                      Text(DateFormat('MMMM yyyy').format(_selectedMonth), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.arrow_right_3, size: 20),
                onPressed: _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                    ? () {
                        setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
                        _loadMonthlyReport();
                      }
                    : null,
              ),
            ],
          ),
        ),

        // Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(children: [
              _buildMiniStat(isDark, 'Present', '$presentDays', AppColors.present),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Late', '$lateDays', AppColors.late_),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Absent', '$absentDays', AppColors.absent),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Leave', '$leaveDays', AppColors.onLeave),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _buildMiniStat(isDark, 'Work Days', '$totalDays', AppColors.primary),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'Hours', '${totalHours.toStringAsFixed(1)}', AppColors.accent),
              const SizedBox(width: 8),
              _buildMiniStat(isDark, 'OT', '${totalOt.toStringAsFixed(1)}h', AppColors.warning),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // Records list
        Expanded(
          child: _monthlyLoading
              ? const Center(child: CircularProgressIndicator())
              : _monthlyRecords.isEmpty
                  ? Center(child: Text('No records for this month', style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _monthlyRecords.length,
                      itemBuilder: (context, index) => _buildRecordCard(isDark, _monthlyRecords[index]),
                    ),
        ),
      ],
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
    // Parse employee name from nested Supabase join
    final emp = record['employee'];
    String name = 'Unknown';
    if (emp is Map<String, dynamic>) {
      final fn = emp['first_name'] ?? '';
      final ln = emp['last_name'] ?? '';
      name = '$fn $ln'.trim();
      if (name.isEmpty) name = emp['name_mm'] ?? emp['employee_code'] ?? 'Unknown';
    }

    final status = record['status'] ?? 'absent';

    // Format check-in/out times
    String? ciFormatted;
    String? coFormatted;
    if (record['check_in_time'] != null) {
      final ci = DateTime.tryParse(record['check_in_time'].toString());
      ciFormatted = ci != null ? DateFormat('h:mm a').format(ci.toLocal()) : null;
    }
    if (record['check_out_time'] != null) {
      final co = DateTime.tryParse(record['check_out_time'].toString());
      coFormatted = co != null ? DateFormat('h:mm a').format(co.toLocal()) : null;
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'present': statusColor = AppColors.present; statusIcon = Iconsax.tick_circle; break;
      case 'late': statusColor = AppColors.late_; statusIcon = Iconsax.clock; break;
      case 'on_leave': statusColor = AppColors.onLeave; statusIcon = Iconsax.calendar_1; break;
      default: statusColor = AppColors.absent; statusIcon = Iconsax.close_circle;
    }

    // Format total hours
    final totalH = (record['total_hours'] ?? 0).toDouble();
    final hoursStr = totalH > 0 ? '${totalH.floor()}h ${((totalH - totalH.floor()) * 60).round()}m' : '';

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
                if (ciFormatted != null) Text(
                  'In: $ciFormatted${coFormatted != null ? ' • Out: $coFormatted' : ''}${hoursStr.isNotEmpty ? ' • $hoursStr' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
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