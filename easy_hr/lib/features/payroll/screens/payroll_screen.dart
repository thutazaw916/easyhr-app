import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/payslip_pdf_service.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;
  List<Map<String, dynamic>> _payrollList = [];
  Map<String, dynamic>? _myPayslip;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _salaryStructures = [];

  @override
  void initState() {
    super.initState();
    final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;
    _tabController = TabController(length: isAdmin ? 3 : 1, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;

      if (isAdmin) {
        try {
          final result = await api.getMonthlyPayroll(_selectedYear, _selectedMonth);
          final list = result['payrolls'] ?? result['payroll'] ?? [];
          _payrollList = List<Map<String, dynamic>>.from(list);
        } catch (_) {
          _payrollList = [];
        }
        try {
          final empResult = await api.listEmployees();
          _employees = List<Map<String, dynamic>>.from(empResult['employees'] ?? []);
        } catch (_) {
          _employees = [];
        }
        try {
          _salaryStructures = List<Map<String, dynamic>>.from(await api.getAllSalaryStructures());
        } catch (_) {
          _salaryStructures = [];
        }
      }

      try {
        _myPayslip = await api.getMyPayslip(_selectedYear, _selectedMonth);
      } catch (_) {
        _myPayslip = null;
      }
    } catch (_) {
      _payrollList = [];
      _myPayslip = null;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payroll'),
        actions: [
          if (isAdmin) ...[
            IconButton(icon: const Icon(Iconsax.setting_3), tooltip: 'Salary Components', onPressed: () => context.push('/payroll/components')),
            IconButton(icon: const Icon(Iconsax.calculator), tooltip: 'Calculate Payroll', onPressed: () => _showCalculateDialog(context, isDark)),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isAdmin,
          tabs: [
            if (isAdmin) ...[
              const Tab(text: 'Overview', icon: Icon(Iconsax.chart_square, size: 18)),
              const Tab(text: 'Salary Setup', icon: Icon(Iconsax.money_send, size: 18)),
            ],
            const Tab(text: 'My Payslip', icon: Icon(Iconsax.receipt_item, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (isAdmin) ...[
            _buildOverviewTab(isDark),
            _buildSalarySetupTab(isDark),
          ],
          _buildMyPayslipTab(isDark),
        ],
      ),
    );
  }

  // ============================================
  // OVERVIEW TAB (Admin)
  // ============================================
  Widget _buildOverviewTab(bool isDark) {
    final totalGross = _payrollList.fold<double>(0, (sum, p) => sum + ((p['gross_salary'] ?? 0) as num).toDouble());
    final totalNet = _payrollList.fold<double>(0, (sum, p) => sum + ((p['net_salary'] ?? 0) as num).toDouble());
    final totalDeductions = _payrollList.fold<double>(0, (sum, p) => sum + ((p['total_deductions'] ?? 0) as num).toDouble());

    return Column(
      children: [
        // Month Selector
        _buildMonthSelector(isDark),

        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildSummaryCard(isDark, 'Total Gross', _formatMoney(totalGross), AppColors.primary, Iconsax.money_send),
              const SizedBox(width: 10),
              _buildSummaryCard(isDark, 'Total Net', _formatMoney(totalNet), AppColors.present, Iconsax.money_recive),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildSummaryCard(isDark, 'Deductions', _formatMoney(totalDeductions), AppColors.absent, Iconsax.money_remove),
              const SizedBox(width: 10),
              _buildSummaryCard(isDark, 'Employees', '${_payrollList.length}', AppColors.info, Iconsax.people5),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Admin Action Buttons (Approve / Send)
        if (_payrollList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      icon: const Icon(Iconsax.tick_circle, size: 16),
                      label: const Text('Approve All', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.present,
                        side: const BorderSide(color: AppColors.present),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          final api = ref.read(apiServiceProvider);
                          final result = await api.approvePayroll(_selectedYear, _selectedMonth);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message']?.toString() ?? 'Approved'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: const Icon(Iconsax.send_1, size: 16),
                      label: const Text('Send Payslips', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          final api = ref.read(apiServiceProvider);
                          final result = await api.sendPayslips(_selectedYear, _selectedMonth);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message']?.toString() ?? 'Payslips sent'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Payroll List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _payrollList.isEmpty
                  ? _buildEmptyPayroll(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _payrollList.length,
                      itemBuilder: (context, index) => _buildPayrollCard(isDark, _payrollList[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyPayroll(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Iconsax.calculator, size: 40, color: AppColors.warning),
          ),
          const SizedBox(height: 16),
          Text('No payroll calculated', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap the calculator icon to run payroll', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.calculator, size: 18),
            label: const Text('Calculate Now'),
            onPressed: () => _showCalculateDialog(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(bool isDark, Map<String, dynamic> payroll) {
    final emp = payroll['employee'];
    final name = emp is Map
        ? '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim()
        : payroll['employee_name']?.toString();
    final displayName = (name != null && name.isNotEmpty) ? name : 'Unknown';
    final gross = ((payroll['gross_salary'] ?? 0) as num).toDouble();
    final net = ((payroll['net_salary'] ?? 0) as num).toDouble();
    final status = payroll['status'] ?? 'draft';

    Color statusColor;
    switch (status) {
      case 'approved': statusColor = AppColors.present; break;
      case 'paid': statusColor = AppColors.info; break;
      default: statusColor = AppColors.warning;
    }

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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(displayName.isNotEmpty ? displayName[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Gross: ${_formatMoney(gross)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('Net: ${_formatMoney(net)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.present)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SALARY SETUP TAB (Admin) - Functional
  // ============================================
  Widget _buildSalarySetupTab(bool isDark) {
    // Match employees with their salary structures
    final structureMap = <String, Map<String, dynamic>>{};
    for (final s in _salaryStructures) {
      final empId = s['employee_id']?.toString() ?? '';
      if (empId.isNotEmpty) structureMap[empId] = s;
    }

    final configured = _employees.where((e) => structureMap.containsKey(e['id']?.toString())).toList();
    final notConfigured = _employees.where((e) => !structureMap.containsKey(e['id']?.toString())).toList();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.info.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${configured.length}/${_employees.length} employees have salary configured',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Not configured employees
                  if (notConfigured.isNotEmpty) ...[  
                    const SizedBox(height: 16),
                    Text('⚠️ Salary Not Set (${notConfigured.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.warning)),
                    const SizedBox(height: 8),
                    ...notConfigured.map((emp) => _buildEmployeeSalaryCard(isDark, emp, null)),
                  ],

                  if (configured.isNotEmpty) ...[  
                    const SizedBox(height: 16),
                    Text('✅ Configured (${configured.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.present)),
                    const SizedBox(height: 8),
                    ...configured.map((emp) => _buildEmployeeSalaryCard(isDark, emp, structureMap[emp['id']?.toString()])),
                  ],

                  if (_employees.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Iconsax.people5, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            const SizedBox(height: 12),
                            const Text('No employees found', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
  }

  Widget _buildEmployeeSalaryCard(bool isDark, Map<String, dynamic> emp, Map<String, dynamic>? structure) {
    final name = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final code = emp['employee_code'] ?? '';
    final hasStructure = structure != null;
    final baseSalary = hasStructure ? ((structure['basic_salary'] ?? 0) as num).toDouble() : 0.0;

    return GestureDetector(
      onTap: () => _showSalarySetupDialog(isDark, emp, structure),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasStructure
                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                : AppColors.warning.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (hasStructure ? AppColors.present : AppColors.warning).withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: hasStructure ? AppColors.present : AppColors.warning, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Unnamed' : name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(code.toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (hasStructure)
              Text(_formatMoney(baseSalary), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.present))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('Set Salary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
            const SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  void _showSalarySetupDialog(bool isDark, Map<String, dynamic> emp, Map<String, dynamic>? existing) {
    final name = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final basicC = TextEditingController(text: existing != null ? '${(existing['basic_salary'] ?? 0)}' : '');
    final transportC = TextEditingController(text: existing != null ? '${(existing['transport_allowance'] ?? 0)}' : '0');
    final mealC = TextEditingController(text: existing != null ? '${(existing['meal_allowance'] ?? 0)}' : '0');
    final phoneC = TextEditingController(text: existing != null ? '${(existing['phone_allowance'] ?? 0)}' : '0');
    final otRateC = TextEditingController(text: existing != null ? '${(existing['ot_rate_per_hour'] ?? 0)}' : '0');
    bool saving = false;

    // Custom components list
    final List<Map<String, TextEditingController>> customComponents = [];
    if (existing != null && existing['custom_components'] != null) {
      final List<dynamic> saved = existing['custom_components'] is List ? existing['custom_components'] : [];
      for (final c in saved) {
        customComponents.add({
          'name': TextEditingController(text: c['name']?.toString() ?? ''),
          'amount': TextEditingController(text: '${c['amount'] ?? 0}'),
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('💰 Salary Setup', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(name, style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),

                _buildSalaryField('Basic Salary (MMK) *', basicC, Iconsax.money_send),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildSalaryField('Transport', transportC, Iconsax.car)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSalaryField('Meal', mealC, Iconsax.coffee)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildSalaryField('Phone', phoneC, Iconsax.call)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSalaryField('OT Rate/hr', otRateC, Iconsax.clock)),
                ]),

                // Custom Components Section
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Custom Allowances', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    InkWell(
                      onTap: () {
                        setBS(() {
                          customComponents.add({
                            'name': TextEditingController(),
                            'amount': TextEditingController(text: '0'),
                          });
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.add, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(customComponents.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: customComponents[i]['name'],
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Iconsax.tag, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: customComponents[i]['amount'],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'MMK',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setBS(() => customComponents.removeAt(i)),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Iconsax.trash, size: 18, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (customComponents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Text(
                      'Tap + Add to create custom allowances',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Iconsax.tick_circle, size: 18),
                    label: Text(saving ? 'Saving...' : 'Save Salary Structure', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: saving
                        ? null
                        : () async {
                            final basic = double.tryParse(basicC.text) ?? 0;
                            if (basic <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter base salary'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }
                            setBS(() => saving = true);
                            try {
                              final api = ref.read(apiServiceProvider);
                              // Build custom components list
                              final List<Map<String, dynamic>> customList = [];
                              for (final c in customComponents) {
                                final cName = c['name']!.text.trim();
                                final cAmount = double.tryParse(c['amount']!.text) ?? 0;
                                if (cName.isNotEmpty) {
                                  customList.add({'name': cName, 'amount': cAmount, 'type': 'earning'});
                                }
                              }
                              await api.setSalaryStructure(emp['id'].toString(), {
                                'basic_salary': basic,
                                'transport_allowance': double.tryParse(transportC.text) ?? 0,
                                'meal_allowance': double.tryParse(mealC.text) ?? 0,
                                'phone_allowance': double.tryParse(phoneC.text) ?? 0,
                                'ot_rate_per_hour': double.tryParse(otRateC.text) ?? 0,
                                'custom_components': customList,
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✅ Salary set for $name'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              setBS(() => saving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('❌ Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSalaryField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildSalaryComponent(bool isDark, String name, String value, IconData icon, Color color) {
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
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildFormulaRow(String text, String sign, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text(sign, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sign == '-' ? AppColors.absent : AppColors.present))),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: text.startsWith('=') ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  // ============================================
  // MY PAYSLIP TAB
  // ============================================
  Widget _buildMyPayslipTab(bool isDark) {
    return Column(
      children: [
        _buildMonthSelector(isDark),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myPayslip == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Iconsax.receipt_item, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('No payslip available', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildPayslipDetail(isDark, _myPayslip!),
                    ),
        ),
      ],
    );
  }

  Widget _buildPayslipDetail(bool isDark, Map<String, dynamic> payslip) {
    final basicSalary = _toDouble(payslip['basic_salary']);
    final totalAllowances = _toDouble(payslip['total_allowances']);
    final otAmount = _toDouble(payslip['ot_amount']);
    final otHours = _toDouble(payslip['ot_hours']);
    final attendanceBonus = _toDouble(payslip['attendance_bonus']);
    final bonus = _toDouble(payslip['bonus']);
    final otherEarnings = _toDouble(payslip['other_earnings']);
    final grossSalary = _toDouble(payslip['gross_salary']);
    final ssbAmount = _toDouble(payslip['ssb_amount']);
    final taxAmount = _toDouble(payslip['tax_amount']);
    final advanceDeduction = _toDouble(payslip['advance_deduction']);
    final otherDeductions = _toDouble(payslip['other_deductions']);
    final totalDeductions = _toDouble(payslip['total_deductions']);
    final netSalary = _toDouble(payslip['net_salary']);
    final status = payslip['status'] ?? 'draft';
    final daysPresent = payslip['days_present'] ?? 0;
    final daysAbsent = payslip['days_absent'] ?? 0;
    final daysLate = payslip['days_late'] ?? 0;
    final daysOnLeave = payslip['days_on_leave'] ?? 0;
    final totalWorkingDays = payslip['total_working_days'] ?? 0;
    final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;

    final isMm = (ref.read(authProvider).user?.language ?? 'en') == 'mm';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved': statusColor = AppColors.present; statusLabel = isMm ? 'အတည်ပြုပြီး' : 'APPROVED'; break;
      case 'paid': statusColor = AppColors.info; statusLabel = isMm ? 'ပေးချေပြီး' : 'PAID'; break;
      default: statusColor = AppColors.warning; statusLabel = isMm ? 'တွက်ချက်ပြီး' : 'CALCULATED';
    }

    return Column(
      children: [
        // Net Salary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(isMm ? 'လက်ခံရရှိငွေ' : 'Net Salary', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_formatMoneyFull(netSalary), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Attendance Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attendanceStat(isMm ? 'အလုပ်ရက်' : 'Work Days', '$totalWorkingDays', AppColors.primary),
              _attendanceStat(isMm ? 'တက်ရက်' : 'Present', '$daysPresent', AppColors.present),
              _attendanceStat(isMm ? 'ပျက်ရက်' : 'Absent', '$daysAbsent', AppColors.absent),
              _attendanceStat(isMm ? 'နောက်ကျ' : 'Late', '$daysLate', AppColors.warning),
              _attendanceStat(isMm ? 'ခွင့်' : 'Leave', '$daysOnLeave', AppColors.info),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Earnings Section - Individual Breakdown
        _buildPayslipSection(isDark, isMm ? 'ဝင်ငွေအသေးစိတ်' : 'Earnings', AppColors.present, [
          _buildPayslipRow(isMm ? 'အခြေခံလစာ' : 'Basic Salary', _formatMoneyFull(basicSalary), AppColors.present),
          if (_toDouble(payslip['transport_allowance']) > 0)
            _buildPayslipRow(isMm ? 'သွားလာစရိတ်' : 'Transport Allowance', _formatMoneyFull(_toDouble(payslip['transport_allowance'])), AppColors.present),
          if (_toDouble(payslip['meal_allowance']) > 0)
            _buildPayslipRow(isMm ? 'ထမင်းစရိတ်' : 'Meal Allowance', _formatMoneyFull(_toDouble(payslip['meal_allowance'])), AppColors.present),
          if (_toDouble(payslip['phone_allowance']) > 0)
            _buildPayslipRow(isMm ? 'ဖုန်းစရိတ်' : 'Phone Allowance', _formatMoneyFull(_toDouble(payslip['phone_allowance'])), AppColors.present),
          if (_toDouble(payslip['housing_allowance']) > 0)
            _buildPayslipRow(isMm ? 'အိမ်ခန်းစရိတ်' : 'Housing Allowance', _formatMoneyFull(_toDouble(payslip['housing_allowance'])), AppColors.present),
          if (_toDouble(payslip['position_allowance']) > 0)
            _buildPayslipRow(isMm ? 'ရာထူးစရိတ်' : 'Position Allowance', _formatMoneyFull(_toDouble(payslip['position_allowance'])), AppColors.present),
          if (_toDouble(payslip['other_allowance']) > 0)
            _buildPayslipRow(isMm ? 'အခြားစရိတ်' : 'Other Allowance', _formatMoneyFull(_toDouble(payslip['other_allowance'])), AppColors.present),
          if (attendanceBonus > 0)
            _buildPayslipRow(isMm ? 'ရက်မှန်ကြေး' : 'Attendance Bonus', _formatMoneyFull(attendanceBonus), AppColors.present),
          if (otAmount > 0)
            _buildPayslipRow(isMm ? 'အချိန်ပိုကြေး (${otHours.toStringAsFixed(1)}h)' : 'Overtime (${otHours.toStringAsFixed(1)}h)', _formatMoneyFull(otAmount), AppColors.present),
          if (_toDouble(payslip['performance_bonus']) > 0)
            _buildPayslipRow(isMm ? 'စွမ်းဆောင်ရည်ဆုကြေး' : 'Performance Bonus', _formatMoneyFull(_toDouble(payslip['performance_bonus'])), AppColors.present),
          if (_toDouble(payslip['incentive']) > 0)
            _buildPayslipRow(isMm ? 'မက်လုံး' : 'Incentive', _formatMoneyFull(_toDouble(payslip['incentive'])), AppColors.present),
          if (_toDouble(payslip['commission']) > 0)
            _buildPayslipRow(isMm ? 'ကော်မရှင်' : 'Commission', _formatMoneyFull(_toDouble(payslip['commission'])), AppColors.present),
          if (bonus > 0)
            _buildPayslipRow(payslip['bonus_description']?.toString().isNotEmpty == true ? payslip['bonus_description'].toString() : (isMm ? 'ဆုကြေး' : 'Bonus'), _formatMoneyFull(bonus), AppColors.present),
          if (otherEarnings > 0)
            _buildPayslipRow(payslip['other_earnings_description']?.toString().isNotEmpty == true ? payslip['other_earnings_description'].toString() : (isMm ? 'အခြားရရှိငွေ' : 'Other Earnings'), _formatMoneyFull(otherEarnings), AppColors.present),
          const Divider(height: 16),
          _buildPayslipRow(isMm ? 'စုစုပေါင်းဝင်ငွေ' : 'Gross Salary', _formatMoneyFull(grossSalary), AppColors.primary, isBold: true),
        ]),

        const SizedBox(height: 12),

        // Deductions Section - Individual Breakdown
        _buildPayslipSection(isDark, isMm ? 'နုတ်ယူငွေအသေးစိတ်' : 'Deductions', AppColors.absent, [
          if (ssbAmount > 0)
            _buildPayslipRow(isMm ? 'လူမှုဖူလုံရေး (SSB)' : 'Social Security (SSB)', _formatMoneyFull(ssbAmount), AppColors.absent),
          if (taxAmount > 0)
            _buildPayslipRow(isMm ? 'ဝင်ငွေခွန်' : 'Income Tax', _formatMoneyFull(taxAmount), AppColors.absent),
          if (advanceDeduction > 0)
            _buildPayslipRow(isMm ? 'ကြိုတင်ထုတ်ငွေ' : 'Salary Advance', _formatMoneyFull(advanceDeduction), AppColors.warning),
          if (_toDouble(payslip['absent_deduction']) > 0)
            _buildPayslipRow(isMm ? 'ပျက်ကွက်နုတ်ငွေ' : 'Absent Deduction', _formatMoneyFull(_toDouble(payslip['absent_deduction'])), AppColors.absent),
          if (_toDouble(payslip['unpaid_leave_deduction']) > 0)
            _buildPayslipRow(isMm ? 'ခွင့်မဲ့နုတ်ငွေ' : 'Unpaid Leave Ded.', _formatMoneyFull(_toDouble(payslip['unpaid_leave_deduction'])), AppColors.absent),
          if (_toDouble(payslip['late_deduction']) > 0)
            _buildPayslipRow(isMm ? 'နောက်ကျနုတ်ငွေ' : 'Late Deduction', _formatMoneyFull(_toDouble(payslip['late_deduction'])), AppColors.absent),
          if (_toDouble(payslip['loan_deduction']) > 0)
            _buildPayslipRow(isMm ? 'ချေးငွေပြန်ဆပ်' : 'Loan Repayment', _formatMoneyFull(_toDouble(payslip['loan_deduction'])), AppColors.absent),
          if (_toDouble(payslip['insurance_deduction']) > 0)
            _buildPayslipRow(isMm ? 'အာမခံ' : 'Insurance', _formatMoneyFull(_toDouble(payslip['insurance_deduction'])), AppColors.absent),
          if (_toDouble(payslip['uniform_deduction']) > 0)
            _buildPayslipRow(isMm ? 'ယူနီဖောင်းနုတ်ငွေ' : 'Uniform Deduction', _formatMoneyFull(_toDouble(payslip['uniform_deduction'])), AppColors.absent),
          if (otherDeductions > 0)
            _buildPayslipRow(payslip['other_deductions_description']?.toString().isNotEmpty == true ? payslip['other_deductions_description'].toString() : (isMm ? 'အခြားနုတ်ယူငွေ' : 'Other Deductions'), _formatMoneyFull(otherDeductions), AppColors.absent),
          if (totalDeductions == 0)
            _buildPayslipRow(isMm ? 'နုတ်ယူငွေမရှိ' : 'No deductions', '-', Colors.grey),
          const Divider(height: 16),
          _buildPayslipRow(isMm ? 'စုစုပေါင်းနုတ်ယူငွေ' : 'Total Deductions', _formatMoneyFull(totalDeductions), AppColors.absent, isBold: true),
        ]),

        const SizedBox(height: 20),

        // Admin: Edit Payment
        if (isAdmin) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Iconsax.edit, size: 18),
              label: Text(isMm ? 'လစာပြင်ဆင်ရန်' : 'Edit Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showEditPaymentDialog(isDark, payslip),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Download PDF - Language Choice
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.document_download, size: 18),
                  label: const Text('PDF (EN)', style: TextStyle(fontSize: 13)),
                  onPressed: () => _previewPdf(payslip, 'en'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.document_download, size: 18),
                  label: const Text('PDF (MM)', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: () => _previewPdf(payslip, 'mm'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.present, padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => _sharePdf(payslip, isMm ? 'mm' : 'en'),
                child: const Icon(Iconsax.share, size: 18),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _attendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
      ],
    );
  }

  double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

  String _formatMoneyFull(double amount) {
    if (amount == 0) return '0 MMK';
    return '${NumberFormat('#,###').format(amount.round())} MMK';
  }

  Future<void> _previewPdf(Map<String, dynamic> payslip, String lang) async {
    try {
      await PayslipPdfService.generateAndPreview(payslip, _selectedYear, _selectedMonth, lang: lang);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sharePdf(Map<String, dynamic> payslip, String lang) async {
    try {
      await PayslipPdfService.sharePdf(payslip, _selectedYear, _selectedMonth, lang: lang);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showEditPaymentDialog(bool isDark, Map<String, dynamic> payslip) {
    // Earnings controllers
    final cBasic = TextEditingController(text: '${payslip['basic_salary'] ?? 0}');
    final cAttendanceBonus = TextEditingController(text: '${payslip['attendance_bonus'] ?? 0}');
    final cOtAmount = TextEditingController(text: '${payslip['ot_amount'] ?? 0}');
    final cTransport = TextEditingController(text: '${payslip['transport_allowance'] ?? 0}');
    final cMeal = TextEditingController(text: '${payslip['meal_allowance'] ?? 0}');
    final cPhone = TextEditingController(text: '${payslip['phone_allowance'] ?? 0}');
    final cHousing = TextEditingController(text: '${payslip['housing_allowance'] ?? 0}');
    final cPosition = TextEditingController(text: '${payslip['position_allowance'] ?? 0}');
    final cOtherAllowance = TextEditingController(text: '${payslip['other_allowance'] ?? 0}');
    final cPerfBonus = TextEditingController(text: '${payslip['performance_bonus'] ?? 0}');
    final cIncentive = TextEditingController(text: '${payslip['incentive'] ?? 0}');
    final cCommission = TextEditingController(text: '${payslip['commission'] ?? 0}');
    final cBonus = TextEditingController(text: '${payslip['bonus'] ?? 0}');
    final cBonusDesc = TextEditingController(text: payslip['bonus_description']?.toString() ?? '');
    final cOtherEarnings = TextEditingController(text: '${payslip['other_earnings'] ?? 0}');
    final cOtherEarningsDesc = TextEditingController(text: payslip['other_earnings_description']?.toString() ?? '');
    // Deductions controllers
    final cSsb = TextEditingController(text: '${payslip['ssb_amount'] ?? 0}');
    final cTax = TextEditingController(text: '${payslip['tax_amount'] ?? 0}');
    final cAdvance = TextEditingController(text: '${payslip['advance_deduction'] ?? 0}');
    final cAbsentDed = TextEditingController(text: '${payslip['absent_deduction'] ?? 0}');
    final cUnpaidLeave = TextEditingController(text: '${payslip['unpaid_leave_deduction'] ?? 0}');
    final cLateDed = TextEditingController(text: '${payslip['late_deduction'] ?? 0}');
    final cLoan = TextEditingController(text: '${payslip['loan_deduction'] ?? 0}');
    final cInsurance = TextEditingController(text: '${payslip['insurance_deduction'] ?? 0}');
    final cUniform = TextEditingController(text: '${payslip['uniform_deduction'] ?? 0}');
    final cOtherDed = TextEditingController(text: '${payslip['other_deductions'] ?? 0}');
    final cOtherDedDesc = TextEditingController(text: payslip['other_deductions_description']?.toString() ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        Widget field(String label, TextEditingController c, {bool desc = false}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: c,
              keyboardType: desc ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          );
        }

        Widget sectionHeader(String title, Color color, IconData icon) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ]),
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollC) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
            child: Column(
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Iconsax.edit, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Edit Payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(DateFormat('MMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    controller: scrollC,
                    children: [
                      // ── EARNINGS ──
                      sectionHeader('ဝင်ငွေ / Earnings', AppColors.present, Iconsax.money_add),
                      field('Basic Salary / အခြေခံလစာ', cBasic),
                      Row(children: [
                        Expanded(child: field('Transport / သွားလာစရိတ်', cTransport)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Meal / ထမင်းစရိတ်', cMeal)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Phone / ဖုန်းစရိတ်', cPhone)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Housing / အိမ်ခန်းစရိတ်', cHousing)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Position / ရာထူးစရိတ်', cPosition)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Other Allow / အခြားစရိတ်', cOtherAllowance)),
                      ]),
                      field('Attendance Bonus / ရက်မှန်ကြေး', cAttendanceBonus),
                      field('Overtime / အချိန်ပိုကြေး', cOtAmount),
                      Row(children: [
                        Expanded(child: field('Perf. Bonus / စွမ်းဆောင်ရည်', cPerfBonus)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Incentive / မက်လုံး', cIncentive)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Commission / ကော်မရှင်', cCommission)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Bonus / ဆုကြေး', cBonus)),
                      ]),
                      field('Bonus Desc', cBonusDesc, desc: true),
                      field('Other Earnings / အခြားရရှိငွေ', cOtherEarnings),
                      field('Other Earnings Desc', cOtherEarningsDesc, desc: true),

                      // ── DEDUCTIONS ──
                      sectionHeader('နုတ်ယူငွေ / Deductions', AppColors.absent, Iconsax.money_remove),
                      Row(children: [
                        Expanded(child: field('SSB / လူမှုဖူလုံရေး', cSsb)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Tax / ဝင်ငွေခွန်', cTax)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Advance / ကြိုတင်ထုတ်', cAdvance)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Absent / ပျက်ကွက်နုတ်', cAbsentDed)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Unpaid Leave / ခွင့်မဲ့နုတ်', cUnpaidLeave)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Late / နောက်ကျနုတ်', cLateDed)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Loan / ချေးငွေပြန်ဆပ်', cLoan)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Insurance / အာမခံ', cInsurance)),
                      ]),
                      Row(children: [
                        Expanded(child: field('Uniform / ယူနီဖောင်း', cUniform)),
                        const SizedBox(width: 6),
                        Expanded(child: field('Other Ded / အခြားနုတ်', cOtherDed)),
                      ]),
                      field('Other Deductions Desc', cOtherDedDesc, desc: true),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Iconsax.tick_circle, size: 18),
                    label: Text(saving ? 'Saving...' : 'Save All Changes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: saving ? null : () async {
                      setBS(() => saving = true);
                      try {
                        double p(TextEditingController c) => double.tryParse(c.text) ?? 0;
                        final api = ref.read(apiServiceProvider);
                        await api.adjustPayroll(payslip['id'].toString(), {
                          'basic_salary': p(cBasic),
                          'attendance_bonus': p(cAttendanceBonus),
                          'ot_amount': p(cOtAmount),
                          'transport_allowance': p(cTransport),
                          'meal_allowance': p(cMeal),
                          'phone_allowance': p(cPhone),
                          'housing_allowance': p(cHousing),
                          'position_allowance': p(cPosition),
                          'other_allowance': p(cOtherAllowance),
                          'performance_bonus': p(cPerfBonus),
                          'incentive': p(cIncentive),
                          'commission': p(cCommission),
                          'bonus': p(cBonus),
                          'bonus_description': cBonusDesc.text.trim(),
                          'other_earnings': p(cOtherEarnings),
                          'other_earnings_description': cOtherEarningsDesc.text.trim(),
                          'ssb_amount': p(cSsb),
                          'tax_amount': p(cTax),
                          'advance_deduction': p(cAdvance),
                          'absent_deduction': p(cAbsentDed),
                          'unpaid_leave_deduction': p(cUnpaidLeave),
                          'late_deduction': p(cLateDed),
                          'loan_deduction': p(cLoan),
                          'insurance_deduction': p(cInsurance),
                          'uniform_deduction': p(cUniform),
                          'other_deductions': p(cOtherDed),
                          'other_deductions_description': cOtherDedDesc.text.trim(),
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment updated successfully'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        setBS(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPayslipSection(bool isDark, String title, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
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
              Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPayslipRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  // ============================================
  // SHARED WIDGETS
  // ============================================
  Widget _buildMonthSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2, size: 20),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; }
                else { _selectedMonth--; }
              });
              _loadData();
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
                  Text(DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_3, size: 20),
            onPressed: () {
              final now = DateTime.now();
              if (_selectedYear < now.year || (_selectedYear == now.year && _selectedMonth < now.month)) {
                setState(() {
                  if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; }
                  else { _selectedMonth++; }
                });
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${NumberFormat('#,###').format(amount)} K';
    return '${amount.round()} MMK';
  }

  void _showCalculateDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.calculator, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Calculate Payroll'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculate payroll for:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.calendar, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('This will calculate salary for all active employees based on attendance, allowances, and deductions.',
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final api = ref.read(apiServiceProvider);
                final result = await api.calculatePayroll(_selectedYear, _selectedMonth);
                final msg = result['message']?.toString() ?? 'Payroll calculated!';
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ $msg'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                  );
                  _loadData();
                }
              } catch (e) {
                String msg = 'Payroll calculation failed.';
                if (e is DioException) {
                  final status = e.response?.statusCode;
                  final data = e.response?.data;
                  final backendMsg = data is Map ? data['message']?.toString() : null;
                  if (status == 400 || backendMsg != null) {
                    msg = backendMsg ?? 'Set up salary for employees first (Salary Setup / Add Employee base salary).';
                  }
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Calculate'),
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