import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  List<Map<String, dynamic>> _departments = [
    {'id': '1', 'name': 'Management', 'name_mm': 'စီမံခန့်ခွဲရေး', 'head': 'Thuta Zaw', 'count': 3, 'color': 0xFF6366F1},
    {'id': '2', 'name': 'Sales', 'name_mm': 'အရောင်း', 'head': '', 'count': 0, 'color': 0xFF22C55E},
    {'id': '3', 'name': 'Operations', 'name_mm': 'လုပ်ငန်းလည်ပတ်ရေး', 'head': '', 'count': 0, 'color': 0xFFF59E0B},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'ဌာနများ' : 'Departments'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${_departments.length} ${mm ? 'ဌာန' : 'depts'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: _departments.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.hierarchy_square_2, size: 64, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(mm ? 'ဌာနမရှိသေးပါ' : 'No departments yet'),
                const SizedBox(height: 8),
                Text(mm ? 'ဌာနထည့်ပြီး ဝန်ထမ်းများကို ခွဲခြားပါ' : 'Add departments to organize your team',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _departments.length,
              itemBuilder: (context, index) => _buildDeptCard(isDark, mm, index),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeptDialog(isDark, mm),
        icon: const Icon(Iconsax.add_circle, size: 20),
        label: Text(mm ? 'ဌာနထည့်ရန်' : 'Add Department'),
      ),
    );
  }

  Widget _buildDeptCard(bool isDark, bool mm, int index) {
    final d = _departments[index];
    final color = Color(d['color'] as int);
    final name = mm ? (d['name_mm'] ?? d['name']) : d['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Header with color strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Iconsax.hierarchy_square_2, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                      if (d['head'] != null && (d['head'] as String).isNotEmpty)
                        Text('${mm ? 'ဌာနမှူး' : 'Head'}: ${d['head']}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.people, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text('${d['count']}', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _actionBtn(mm ? 'ပြင်ဆင်' : 'Edit', Iconsax.edit_2, AppColors.info, () => _showAddDeptDialog(isDark, mm, editIndex: index)),
                const SizedBox(width: 8),
                _actionBtn(mm ? 'ဝန်ထမ်းကြည့်' : 'Members', Iconsax.people, AppColors.primary, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${d['count']} ${mm ? 'ဝန်ထမ်းရှိပါသည်' : 'members in this department'}'), behavior: SnackBarBehavior.floating),
                  );
                }),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(mm, index),
                  child: const Icon(Iconsax.trash, size: 18, color: AppColors.absent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(bool mm, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(mm ? 'ဌာနဖျက်ရန်' : 'Delete Department'),
        content: Text(mm ? 'ဤဌာနကို ဖျက်ရန် သေချာပါသလား?' : 'Are you sure you want to delete this department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mm ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () {
              setState(() => _departments.removeAt(index));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ ${mm ? 'ဖျက်ပြီး!' : 'Deleted!'}'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(mm ? 'ဖျက်ရန်' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDeptDialog(bool isDark, bool mm, {int? editIndex}) {
    final isEdit = editIndex != null;
    final nameC = TextEditingController(text: isEdit ? _departments[editIndex]['name'] : '');
    final nameMmC = TextEditingController(text: isEdit ? _departments[editIndex]['name_mm'] : '');
    final headC = TextEditingController(text: isEdit ? _departments[editIndex]['head'] : '');
    int selectedColor = isEdit ? _departments[editIndex]['color'] : 0xFF6366F1;

    final colors = [0xFF6366F1, 0xFF22C55E, 0xFFF59E0B, 0xFFEF4444, 0xFF3B82F6, 0xFF8B5CF6, 0xFFEC4899, 0xFF06B6D4, 0xFFF97316, 0xFF14B8A6];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isEdit ? (mm ? 'ဌာနပြင်ဆင်ရန်' : 'Edit Department') : (mm ? 'ဌာနအသစ်ထည့်ရန်' : 'Add Department'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(controller: nameC, decoration: InputDecoration(labelText: mm ? 'ဌာနအမည် (English) *' : 'Name (English) *', prefixIcon: const Icon(Iconsax.hierarchy_square_2, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 10),
              TextField(controller: nameMmC, decoration: InputDecoration(labelText: mm ? 'ဌာနအမည် (မြန်မာ)' : 'Name (Myanmar)', prefixIcon: const Icon(Iconsax.translate, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 10),
              TextField(controller: headC, decoration: InputDecoration(labelText: mm ? 'ဌာနမှူး' : 'Department Head', prefixIcon: const Icon(Iconsax.user, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 14),

              Text(mm ? 'အရောင်ရွေးပါ' : 'Choose Color', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setBS(() => selectedColor = c),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: selectedColor == c ? [BoxShadow(color: Color(c).withOpacity(0.4), blurRadius: 8)] : null,
                    ),
                    child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                )).toList(),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(isEdit ? Iconsax.tick_circle : Iconsax.add_circle, size: 20),
                  label: Text(isEdit ? (mm ? 'သိမ်းရန်' : 'Save') : (mm ? 'ထည့်ရန်' : 'Add')),
                  onPressed: () {
                    if (nameC.text.isEmpty) return;
                    final dept = {
                      'id': isEdit ? _departments[editIndex]['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameC.text, 'name_mm': nameMmC.text.isNotEmpty ? nameMmC.text : nameC.text,
                      'head': headC.text, 'count': isEdit ? _departments[editIndex]['count'] : 0,
                      'color': selectedColor,
                    };
                    setState(() { if (isEdit) { _departments[editIndex] = dept; } else { _departments.add(dept); } });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ ${isEdit ? (mm ? 'ပြင်ဆင်ပြီး!' : 'Updated!') : (mm ? 'ဌာနထည့်ပြီး!' : 'Department added!')}'),
                        backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}