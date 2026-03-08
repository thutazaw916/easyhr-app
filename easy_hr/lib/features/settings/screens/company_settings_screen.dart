import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Work Hours
  TimeOfDay _workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 17, minute: 30);
  int _lateMinutes = 15;
  final Map<String, bool> _workingDays = {
    'monday': true, 'tuesday': true, 'wednesday': true,
    'thursday': true, 'friday': true, 'saturday': false, 'sunday': false,
  };

  // Leave Types
  List<Map<String, dynamic>> _leaveTypes = [
    {'name': 'Casual Leave', 'name_mm': 'ရိုးရိုးခွင့်', 'days': 6, 'color': 0xFF8B5CF6, 'editable': true},
    {'name': 'Annual Leave', 'name_mm': 'နှစ်ပတ်လည်ခွင့်', 'days': 10, 'color': 0xFF3B82F6, 'editable': true},
    {'name': 'Sick Leave', 'name_mm': 'နာမကျန်းခွင့်', 'days': 30, 'color': 0xFFEF4444, 'editable': true},
    {'name': 'Maternity Leave', 'name_mm': 'မီးဖွားခွင့်', 'days': 90, 'color': 0xFFEC4899, 'editable': true},
    {'name': 'Paternity Leave', 'name_mm': 'ဖခင်ခွင့်', 'days': 15, 'color': 0xFF06B6D4, 'editable': true},
    {'name': 'Unpaid Leave', 'name_mm': 'လစာမဲ့ခွင့်', 'days': 0, 'color': 0xFF6B7280, 'editable': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final s = AppStrings.get(lang);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(s['company_settings'] ?? 'Company Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s['work_hours'], icon: const Icon(Iconsax.clock, size: 18)),
            Tab(text: s['leave_settings'], icon: const Icon(Iconsax.calendar_tick, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkHoursTab(isDark, s),
          _buildLeaveTypesTab(isDark, s),
        ],
      ),
    );
  }

  // ============================================
  // WORK HOURS TAB
  // ============================================
  Widget _buildWorkHoursTab(bool isDark, Map<String, String> s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Work Time
          Text(s['work_schedule'] ?? 'Work Schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildTimePicker(isDark, s['work_start'] ?? 'Work Start', _workStart, Iconsax.login, AppColors.present, (t) => setState(() => _workStart = t))),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker(isDark, s['work_end'] ?? 'Work End', _workEnd, Iconsax.logout, AppColors.absent, (t) => setState(() => _workEnd = t))),
            ],
          ),

          const SizedBox(height: 16),

          // Late Threshold
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.clock, size: 20, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(s['late_threshold'] ?? 'Late After (minutes)', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _lateMinutes.toDouble(),
                        min: 0, max: 60,
                        divisions: 12,
                        activeColor: AppColors.warning,
                        label: '$_lateMinutes min',
                        onChanged: (v) => setState(() => _lateMinutes = v.round()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('$_lateMinutes min', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ),
                  ],
                ),
                Text(
                  ref.watch(languageProvider) == 'mm'
                    ? '${_workStart.format(context)} ထက် $_lateMinutes မိနစ် ကျော်ရင် နောက်ကျအဖြစ် မှတ်ယူပါမည်'
                    : 'Employees arriving $_lateMinutes+ minutes after ${_workStart.format(context)} will be marked as late',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Working Days
          Text(s['working_days'] ?? 'Working Days', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Column(
              children: _workingDays.entries.map((entry) {
                final dayKey = entry.key;
                final dayName = s[dayKey] ?? dayKey;
                return SwitchListTile(
                  title: Text(dayName, style: const TextStyle(fontSize: 14)),
                  value: entry.value,
                  activeColor: AppColors.primary,
                  dense: true,
                  onChanged: (v) => setState(() => _workingDays[dayKey] = v),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.tick_circle, size: 20),
              label: Text(s['save_settings'] ?? 'Save Settings'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${s['settings_saved'] ?? 'Settings saved!'}'),
                    backgroundColor: AppColors.present,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimePicker(bool isDark, String label, TimeOfDay time, IconData icon, Color color, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 4),
            Text(time.format(context), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ============================================
  // LEAVE TYPES TAB
  // ============================================
  Widget _buildLeaveTypesTab(bool isDark, Map<String, String> s) {
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Column(
      children: [
        // Info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mm ? 'ခွင့်အမျိုးအစားနှင့် ရက်အရေအတွက်ကို သတ်မှတ်ပါ' : 'Configure leave types and days per year for your company',
                    style: const TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Leave Type List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _leaveTypes.length,
            itemBuilder: (context, index) => _buildLeaveTypeCard(isDark, mm, index),
          ),
        ),

        // Add Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Iconsax.add_circle, size: 20),
              label: Text(s['add_leave_type'] ?? 'Add Leave Type'),
              onPressed: () => _showAddLeaveTypeDialog(isDark, mm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeCard(bool isDark, bool mm, int index) {
    final lt = _leaveTypes[index];
    final color = Color(lt['color'] as int);
    final name = mm ? (lt['name_mm'] ?? lt['name']) : lt['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Iconsax.calendar_tick, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  lt['days'] == 0
                    ? (mm ? 'ကန့်သတ်မရှိ' : 'Unlimited')
                    : '${lt['days']} ${mm ? 'ရက်/နှစ်' : 'days/year'}',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          // Edit Days
          GestureDetector(
            onTap: () => _showEditDaysDialog(isDark, mm, index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(mm ? 'ပြင်ရန်' : 'Edit', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          // Delete
          GestureDetector(
            onTap: () {
              setState(() => _leaveTypes.removeAt(index));
            },
            child: const Icon(Iconsax.trash, size: 18, color: AppColors.absent),
          ),
        ],
      ),
    );
  }

  void _showEditDaysDialog(bool isDark, bool mm, int index) {
    final controller = TextEditingController(text: '${_leaveTypes[index]['days']}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(mm ? 'ခွင့်ရက် ပြင်ဆင်ရန်' : 'Edit Leave Days'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: mm ? 'ရက်အရေအတွက်' : 'Number of days',
            suffixText: mm ? 'ရက်/နှစ်' : 'days/year',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mm ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(controller.text) ?? 0;
              setState(() => _leaveTypes[index]['days'] = days);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ ${mm ? 'ပြင်ဆင်ပြီး!' : 'Updated!'}'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(mm ? 'သိမ်းရန်' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddLeaveTypeDialog(bool isDark, bool mm) {
    final nameC = TextEditingController();
    final nameMmC = TextEditingController();
    final daysC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(mm ? 'ခွင့်အမျိုးအစားအသစ်' : 'New Leave Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: mm ? 'အမည် (English)' : 'Name (English)')),
            const SizedBox(height: 8),
            TextField(controller: nameMmC, decoration: InputDecoration(labelText: mm ? 'အမည် (မြန်မာ)' : 'Name (Myanmar)')),
            const SizedBox(height: 8),
            TextField(controller: daysC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: mm ? 'ရက်/နှစ်' : 'Days per year', suffixText: mm ? 'ရက်' : 'days')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mm ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isEmpty) return;
              setState(() => _leaveTypes.add({
                'name': nameC.text,
                'name_mm': nameMmC.text.isNotEmpty ? nameMmC.text : nameC.text,
                'days': int.tryParse(daysC.text) ?? 0,
                'color': 0xFF8B5CF6,
                'editable': true,
              }));
              Navigator.pop(ctx);
            },
            child: Text(mm ? 'ထည့်ရန်' : 'Add'),
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