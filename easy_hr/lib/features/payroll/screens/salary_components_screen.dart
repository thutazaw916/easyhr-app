import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class SalaryComponentsScreen extends ConsumerStatefulWidget {
  const SalaryComponentsScreen({super.key});

  @override
  ConsumerState<SalaryComponentsScreen> createState() => _SalaryComponentsScreenState();
}

class _SalaryComponentsScreenState extends ConsumerState<SalaryComponentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _components = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComponents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComponents() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getSalaryComponents();
      if (mounted) setState(() { _components = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _earnings => _components.where((c) => c['type'] == 'earning').toList();
  List<dynamic> get _deductions => _components.where((c) => c['type'] == 'deduction').toList();

  void _showAddDialog({Map<String, dynamic>? existing}) {
    final lang = ref.read(languageProvider);
    final mm = lang == 'mm';
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final nameMmCtrl = TextEditingController(text: existing?['name_mm'] ?? '');
    final valueCtrl = TextEditingController(text: (existing?['default_value'] ?? 0).toString());
    String type = existing?['type'] ?? 'earning';
    String category = existing?['category'] ?? 'allowance';
    bool isPercentage = existing?['is_percentage'] ?? false;
    bool isTaxable = existing?['is_taxable'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(isEdit ? (mm ? 'ပြင်ဆင်ရန်' : 'Edit Component') : (mm ? 'အသစ်ထည့်ရန်' : 'Add Component'),
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: mm ? 'အမည် (English)' : 'Name (English)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameMmCtrl,
                  decoration: InputDecoration(
                    labelText: mm ? 'အမည် (မြန်မာ)' : 'Name (Myanmar)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Type
                Row(
                  children: [
                    Expanded(
                      child: _choiceChip(
                        label: mm ? 'ဝင်ငွေ' : 'Earning',
                        icon: Iconsax.arrow_up_2,
                        selected: type == 'earning',
                        color: AppColors.present,
                        onTap: () => setModalState(() => type = 'earning'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _choiceChip(
                        label: mm ? 'နုတ်ယူငွေ' : 'Deduction',
                        icon: Iconsax.arrow_down_1,
                        selected: type == 'deduction',
                        color: AppColors.error,
                        onTap: () => setModalState(() => type = 'deduction'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: mm ? 'အမျိုးအစား' : 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'allowance', child: Text(mm ? 'ထောက်ပံ့ကြေး' : 'Allowance')),
                    DropdownMenuItem(value: 'bonus', child: Text(mm ? 'ဆုကြေး' : 'Bonus')),
                    DropdownMenuItem(value: 'deduction', child: Text(mm ? 'နုတ်ယူငွေ' : 'Deduction')),
                    DropdownMenuItem(value: 'tax', child: Text(mm ? 'အခွန်' : 'Tax')),
                  ],
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 12),

                // Default value
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isPercentage
                        ? (mm ? 'ပုံသေ ရာခိုင်နှုန်း (%)' : 'Default Percentage (%)')
                        : (mm ? 'ပုံသေ ပမာဏ (MMK)' : 'Default Amount (MMK)'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Toggles
                SwitchListTile(
                  value: isPercentage,
                  onChanged: (v) => setModalState(() => isPercentage = v),
                  title: Text(mm ? 'ရာခိုင်နှုန်းဖြင့် (basic ၏%)' : 'Percentage of basic salary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: isTaxable,
                  onChanged: (v) => setModalState(() => isTaxable = v),
                  title: Text(mm ? 'အခွန်ထိရောက်မှု' : 'Taxable'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 20),

                // Save
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) return;
                      final api = ref.read(apiServiceProvider);
                      final payload = {
                        'name': nameCtrl.text.trim(),
                        'name_mm': nameMmCtrl.text.trim().isNotEmpty ? nameMmCtrl.text.trim() : null,
                        'type': type,
                        'category': category,
                        'is_percentage': isPercentage,
                        'default_value': double.tryParse(valueCtrl.text) ?? 0,
                        'is_taxable': isTaxable,
                      };

                      try {
                        if (isEdit) {
                          await api.updateSalaryComponent(existing!['id'], payload);
                        } else {
                          await api.createSalaryComponent(payload);
                        }
                        Navigator.pop(ctx);
                        _loadComponents();
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    icon: Icon(isEdit ? Iconsax.edit : Iconsax.add),
                    label: Text(isEdit ? (mm ? 'သိမ်းမည်' : 'Save') : (mm ? 'ထည့်မည်' : 'Add')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteComponent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Component'),
        content: const Text('This will permanently delete this salary component. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.deleteSalaryComponent(id);
        _loadComponents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _choiceChip({required String label, required IconData icon, required bool selected, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? color : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(mm ? 'လစာ အစိတ်အပိုင်းများ' : 'Salary Components'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: mm ? 'ဝင်ငွေများ' : 'Earnings', icon: const Icon(Iconsax.arrow_up_2, size: 18)),
            Tab(text: mm ? 'နုတ်ယူငွေများ' : 'Deductions', icon: const Icon(Iconsax.arrow_down_1, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Iconsax.add),
        label: Text(mm ? 'အသစ်ထည့်' : 'Add New'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComponentList(_earnings, isDark, mm),
                _buildComponentList(_deductions, isDark, mm),
              ],
            ),
    );
  }

  Widget _buildComponentList(List<dynamic> items, bool isDark, bool mm) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.clipboard_text, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(mm ? 'မရှိသေးပါ' : 'No components yet', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComponents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final c = items[index];
          final isEarning = c['type'] == 'earning';
          final color = isEarning ? AppColors.present : AppColors.error;
          final value = c['default_value'] ?? 0;
          final isPercent = c['is_percentage'] == true;

          return Dismissible(
            key: Key(c['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Iconsax.trash, color: AppColors.error),
            ),
            confirmDismiss: (_) async {
              _deleteComponent(c['id']);
              return false;
            },
            child: GestureDetector(
              onTap: () => _showAddDialog(existing: Map<String, dynamic>.from(c)),
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
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(isEarning ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mm && c['name_mm'] != null ? c['name_mm'] : c['name'],
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                child: Text((c['category'] ?? '').toString().toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                              ),
                              if (c['is_taxable'] == true) ...[
                                const SizedBox(width: 6),
                                const Text('• Taxable', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isPercent ? '${value}%' : '${_formatNumber(value)} MMK',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(dynamic n) {
    final num = double.tryParse(n.toString()) ?? 0;
    if (num >= 1000) {
      return num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    }
    return num.toStringAsFixed(0);
  }
}
