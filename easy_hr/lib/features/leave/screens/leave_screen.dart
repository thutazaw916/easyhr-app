import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/localization/app_strings.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Data from API
  List<Map<String, dynamic>> _leaveTypes = [];
  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> _myRequests = [];
  List<Map<String, dynamic>> _pendingApprovals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;

      try { _leaveTypes = List<Map<String, dynamic>>.from(await api.getLeaveTypes()); } catch (_) { _leaveTypes = []; }
      try { _balances = List<Map<String, dynamic>>.from(await api.getMyLeaveBalances()); } catch (_) { _balances = []; }
      try { _myRequests = List<Map<String, dynamic>>.from(await api.getMyLeaveRequests()); } catch (_) { _myRequests = []; }
      if (isAdmin) {
        try { _pendingApprovals = List<Map<String, dynamic>>.from(await api.getPendingLeaves()); } catch (_) { _pendingApprovals = []; }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  // Helper to get leave type info
  Color _getTypeColor(String? code) {
    switch (code) {
      case 'CL': return const Color(0xFF3B82F6);
      case 'EL': return const Color(0xFF10B981);
      case 'ML': return const Color(0xFFEF4444);
      case 'MAT': return const Color(0xFFF472B6);
      case 'PAT': return const Color(0xFF8B5CF6);
      case 'UL': return const Color(0xFF6B7280);
      case 'WFH': return const Color(0xFFF59E0B);
      case 'CO': return const Color(0xFF14B8A6);
      default: return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String? code) {
    switch (code) {
      case 'CL': return Iconsax.sun_1;
      case 'EL': return Iconsax.medal_star;
      case 'ML': return Iconsax.health;
      case 'MAT': return Iconsax.heart;
      case 'PAT': return Iconsax.people;
      case 'UL': return Iconsax.money_remove;
      case 'WFH': return Iconsax.home_2;
      case 'CO': return Iconsax.refresh;
      default: return Iconsax.calendar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(mm ? 'ခွင့်စီမံခန့်ခွဲမှု' : 'Leave Management'),
        bottom: isAdmin
            ? TabBar(controller: _tabController, tabs: [
                Tab(text: mm ? 'ကျွန်ုပ်ခွင့်' : 'My Leave'),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(mm ? 'ခွင့်ခွင့်ပြုရန်' : 'Approvals'),
                  if (_pendingApprovals.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.absent, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_pendingApprovals.length}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ])),
              ])
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isAdmin
              ? TabBarView(controller: _tabController, children: [_buildMyLeaveTab(isDark, mm), _buildApprovalsTab(isDark, mm)])
              : _buildMyLeaveTab(isDark, mm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestLeaveSheet(isDark, mm),
        icon: const Icon(Iconsax.add_circle, size: 20),
        label: Text(mm ? 'ခွင့်တောင်းရန်' : 'Request Leave'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
    );
  }

  // ==================== MY LEAVE TAB ====================
  Widget _buildMyLeaveTab(bool isDark, bool mm) {
    final totalUsed = _balances.fold<double>(0, (s, b) => s + ((b['used_days'] ?? 0) as num).toDouble());
    final totalPending = _balances.fold<double>(0, (s, b) => s + ((b['pending_days'] ?? 0) as num).toDouble());
    final totalAvailable = _balances.fold<double>(0, (s, b) => s + ((b['available_days'] ?? 0) as num).toDouble());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(children: [
                Text(mm ? '📊 ခွင့်အနှစ်ချုပ် ${DateTime.now().year}' : '📊 Leave Summary ${DateTime.now().year}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _summaryItem(mm ? 'ရရှိနိုင်' : 'Available', '${totalAvailable.toInt()}', Colors.white),
                  Container(width: 1, height: 36, color: Colors.white24),
                  _summaryItem(mm ? 'သုံးပြီး' : 'Used', '${totalUsed.toInt()}', const Color(0xFFFBBF24)),
                  Container(width: 1, height: 36, color: Colors.white24),
                  _summaryItem(mm ? 'စောင့်ဆိုင်း' : 'Pending', '${totalPending.toInt()}', const Color(0xFFFB923C)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Balance Grid
            Text(mm ? 'ခွင့်လက်ကျန်' : 'Leave Balances', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (_balances.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(mm ? 'ခွင့်လက်ကျန် မရှိသေးပါ' : 'No leave balances', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))))
            else
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: _balances.length,
                itemBuilder: (ctx, i) {
                  final b = _balances[i];
                  final lt = b['leave_type'] is Map ? b['leave_type'] as Map : {};
                  final code = lt['code']?.toString();
                  final name = mm ? (lt['name_mm'] ?? lt['name'] ?? code ?? '') : (lt['name'] ?? code ?? '');
                  final total = ((b['total_days'] ?? 0) as num).toDouble();
                  final used = ((b['used_days'] ?? 0) as num).toDouble();
                  final pending = ((b['pending_days'] ?? 0) as num).toDouble();
                  final available = total - used - pending;
                  final pct = total > 0 ? used / total : 0.0;
                  final color = _getTypeColor(code);
                  final icon = _getTypeIcon(code);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
                        const Spacer(),
                        Text(code ?? '', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                      ]),
                      const Spacer(),
                      Text(name.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('${available.toInt()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                        Text(' / ${total.toInt()}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const Spacer(),
                        if (pending > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('${pending.toInt()}P', style: const TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.clamp(0, 1), backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 4)),
                    ]),
                  );
                },
              ),
            const SizedBox(height: 20),

            // My Requests
            Text(mm ? 'ခွင့်တောင်းဆိုမှုများ' : 'My Requests', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (_myRequests.isEmpty)
              _emptyState(isDark, mm, mm ? 'ခွင့်တောင်းဆိုမှု မရှိသေး' : 'No leave requests yet')
            else
              ..._myRequests.map((r) => _buildRequestCard(isDark, mm, r, isApproval: false)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color c) => Column(children: [
    Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);

  // ==================== REQUEST CARD ====================
  Widget _buildRequestCard(bool isDark, bool mm, Map<String, dynamic> req, {required bool isApproval}) {
    final lt = req['leave_type'] is Map ? req['leave_type'] as Map : {};
    final code = lt['code']?.toString();
    final typeName = mm ? (lt['name_mm'] ?? lt['name'] ?? '') : (lt['name'] ?? '');
    final color = _getTypeColor(code);
    final icon = _getTypeIcon(code);
    final status = req['status'] ?? 'pending';
    final totalDays = ((req['total_days'] ?? 0) as num).toDouble();
    final reason = req['reason']?.toString() ?? '';
    final rejectionReason = req['rejection_reason']?.toString();
    final startDate = DateTime.tryParse(req['start_date'] ?? '') ?? DateTime.now();
    final endDate = DateTime.tryParse(req['end_date'] ?? '') ?? DateTime.now();
    final dateFormat = DateFormat('dd MMM');

    // For approval tab - employee info
    final emp = req['employee'] is Map ? req['employee'] as Map : {};
    final empName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final empCode = emp['employee_code'] ?? '';

    final statusColor = status == 'approved' ? AppColors.present : status == 'rejected' ? AppColors.absent : AppColors.warning;
    final statusLabel = status == 'approved' ? (mm ? 'ခွင့်ပြု' : 'Approved') : status == 'rejected' ? (mm ? 'ပယ်ချ' : 'Rejected') : (mm ? 'စောင့်ဆိုင်း' : 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)),
      child: Column(children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isApproval && empName.isNotEmpty) Text('$empName ($empCode)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(typeName.toString(), style: TextStyle(fontWeight: isApproval ? FontWeight.w500 : FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(startDate == endDate ? dateFormat.format(startDate) : '${dateFormat.format(startDate)} → ${dateFormat.format(endDate)}',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Text('${totalDays.toInt()}d', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ]),
        ]),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
              child: Text(reason, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
        ],
        if (status == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [Icon(Iconsax.info_circle, size: 14, color: AppColors.absent.withOpacity(0.7)), const SizedBox(width: 6),
            Expanded(child: Text(rejectionReason, style: TextStyle(fontSize: 10, color: AppColors.absent.withOpacity(0.8), fontStyle: FontStyle.italic)))]),
        ],
        // Admin approve/reject buttons
        if (isApproval && status == 'pending') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SizedBox(height: 38, child: OutlinedButton.icon(icon: const Icon(Iconsax.close_circle, size: 16), label: Text(mm ? 'ပယ်ချ' : 'Reject', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.absent, side: const BorderSide(color: AppColors.absent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _handleReject(req, mm)))),
            const SizedBox(width: 10),
            Expanded(child: SizedBox(height: 38, child: ElevatedButton.icon(icon: const Icon(Iconsax.tick_circle, size: 16), label: Text(mm ? 'ခွင့်ပြု' : 'Approve', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.present, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _handleApprove(req, mm)))),
          ]),
        ],
      ]),
    );
  }

  // ==================== APPROVALS TAB ====================
  Widget _buildApprovalsTab(bool isDark, bool mm) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mm ? 'ခွင့်ပြုရန် စောင့်ဆိုင်းနေသည်' : 'Pending Approvals (${_pendingApprovals.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (_pendingApprovals.isEmpty) _emptyState(isDark, mm, mm ? 'ခွင့်ပြုရန် မရှိပါ' : 'No pending approvals')
          else ..._pendingApprovals.map((r) => _buildRequestCard(isDark, mm, r, isApproval: true)),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _emptyState(bool isDark, bool mm, String text) => Container(width: double.infinity, padding: const EdgeInsets.all(30), child: Column(children: [
    Icon(Iconsax.clipboard_text, size: 40, color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.3)),
    const SizedBox(height: 10),
    Text(text, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
  ]));

  // ==================== API: APPROVE / REJECT ====================
  void _handleApprove(Map<String, dynamic> req, bool mm) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.approveLeave(req['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? '✅ ခွင့်ခွင့်ပြုပြီး' : '✅ Leave approved!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating));
    }
  }

  void _handleReject(Map<String, dynamic> req, bool mm) {
    final reasonC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(mm ? 'ပယ်ချရန် အကြောင်းပြချက်' : 'Rejection Reason'),
      content: TextField(controller: reasonC, maxLines: 3, decoration: InputDecoration(hintText: mm ? 'အကြောင်းပြချက် ရေးပါ...' : 'Enter reason...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mm ? 'မလုပ်တော့' : 'Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final api = ref.read(apiServiceProvider);
              await api.rejectLeave(req['id'], reason: reasonC.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? '❌ ခွင့်ပယ်ချပြီး' : '❌ Leave rejected'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating));
                _loadData();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), behavior: SnackBarBehavior.floating));
            }
          },
          child: Text(mm ? 'ပယ်ချမည်' : 'Reject'),
        ),
      ],
    ));
  }

  // ==================== API: REQUEST LEAVE ====================
  void _showRequestLeaveSheet(bool isDark, bool mm) {
    String? selectedTypeId;
    DateTime? startDate, endDate;
    bool isHalfDay = false;
    String halfDayPeriod = 'morning';
    final reasonC = TextEditingController();
    final dateFormat = DateFormat('dd MMM yyyy');
    bool submitting = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        double totalDays = 0;
        if (startDate != null && endDate != null) totalDays = isHalfDay ? 0.5 : endDate!.difference(startDate!).inDays + 1.0;

        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(mm ? '📝 ခွင့်တောင်းရန်' : '📝 Request Leave', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),

            // Leave type selector from API
            Text(mm ? 'ခွင့်အမျိုးအစား' : 'Leave Type', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _leaveTypes.map((lt) {
              final id = lt['id']?.toString();
              final code = lt['code']?.toString();
              final name = mm ? (lt['name_mm'] ?? lt['name'] ?? code) : (lt['name'] ?? code);
              final color = _getTypeColor(code);
              final icon = _getTypeIcon(code);
              final selected = selectedTypeId == id;
              final bal = _balances.firstWhere((b) {
                final blt = b['leave_type'] is Map ? b['leave_type'] : {};
                return blt['id']?.toString() == id;
              }, orElse: () => {});
              final available = ((bal['available_days'] ?? bal['total_days'] ?? 0) as num).toDouble();

              return GestureDetector(
                onTap: () => setBS(() => selectedTypeId = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: selected ? color : color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? color : color.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 14, color: selected ? Colors.white : color),
                    const SizedBox(width: 6),
                    Text(name.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
                    const SizedBox(width: 4),
                    Text('(${available.toInt()})', style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : color.withOpacity(0.6))),
                  ]),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),

            // Date pickers
            Row(children: [
              Expanded(child: _datePicker(ctx, setBS, mm ? 'စတင်ရက်' : 'Start', startDate, dateFormat, (d) => setBS(() { startDate = d; endDate ??= d; }))),
              const SizedBox(width: 10),
              Expanded(child: _datePicker(ctx, setBS, mm ? 'ပြီးဆုံးရက်' : 'End', endDate, dateFormat, (d) => setBS(() => endDate = d))),
            ]),
            const SizedBox(height: 12),

            // Half day
            Row(children: [
              SizedBox(width: 24, height: 24, child: Checkbox(value: isHalfDay, onChanged: (v) => setBS(() => isHalfDay = v ?? false), activeColor: AppColors.primary)),
              const SizedBox(width: 8),
              Text(mm ? 'တစ်ဝက်ခွင့်' : 'Half Day', style: const TextStyle(fontSize: 13)),
              if (isHalfDay) ...[
                const SizedBox(width: 12),
                ChoiceChip(label: Text(mm ? 'နံနက်' : 'AM', style: const TextStyle(fontSize: 11)), selected: halfDayPeriod == 'morning', onSelected: (_) => setBS(() => halfDayPeriod = 'morning'), selectedColor: AppColors.primary.withOpacity(0.2)),
                const SizedBox(width: 6),
                ChoiceChip(label: Text(mm ? 'ညနေ' : 'PM', style: const TextStyle(fontSize: 11)), selected: halfDayPeriod == 'afternoon', onSelected: (_) => setBS(() => halfDayPeriod = 'afternoon'), selectedColor: AppColors.primary.withOpacity(0.2)),
              ],
            ]),
            if (totalDays > 0) Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Text('${mm ? "စုစုပေါင်း" : "Total"}: $totalDays ${mm ? "ရက်" : "day(s)"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary), textAlign: TextAlign.center)),
            const SizedBox(height: 14),

            // Reason
            TextField(controller: reasonC, maxLines: 3, decoration: InputDecoration(labelText: mm ? 'အကြောင်းပြချက်' : 'Reason', hintText: mm ? 'ခွင့်ယူရသည့် အကြောင်းပြချက်...' : 'Why are you requesting leave...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 18),

            // Submit to API
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
              icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.send_1, size: 18),
              label: Text(submitting ? (mm ? 'တင်နေပါသည်...' : 'Submitting...') : (mm ? 'ခွင့်တောင်းတင်ရန်' : 'Submit Request'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: submitting ? null : () async {
                if (selectedTypeId == null || startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? 'ခွင့်အမျိုးအစားနှင့် ရက်စွဲ ရွေးပါ' : 'Select leave type and dates'), behavior: SnackBarBehavior.floating));
                  return;
                }
                if (reasonC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? 'အကြောင်းပြချက် ရေးပါ' : 'Please enter a reason'), behavior: SnackBarBehavior.floating));
                  return;
                }
                setBS(() => submitting = true);
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.requestLeave({
                    'leave_type_id': selectedTypeId,
                    'start_date': '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                    'end_date': '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
                    'reason': reasonC.text.trim(),
                    'is_half_day': isHalfDay,
                    'half_day_period': isHalfDay ? halfDayPeriod : null,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? '✅ ခွင့်တောင်းဆိုမှု တင်ပြီး!' : '✅ Leave request submitted!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating));
                    _loadData();
                  }
                } catch (e) {
                  setBS(() => submitting = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating));
                }
              },
            )),
          ])),
        );
      }),
    );
  }

  Widget _datePicker(BuildContext ctx, StateSetter setBS, String label, DateTime? date, DateFormat fmt, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: date ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 7)), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Iconsax.calendar_1, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            Text(date != null ? fmt.format(date) : '--', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: date != null ? null : Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}