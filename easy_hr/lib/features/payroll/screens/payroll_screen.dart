import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          if (isAdmin)
            IconButton(icon: const Icon(Iconsax.calculator), tooltip: 'Calculate Payroll', onPressed: () => _showCalculateDialog(context, isDark)),
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
                              await api.setSalaryStructure(emp['id'].toString(), {
                                'basic_salary': basic,
                                'transport_allowance': double.tryParse(transportC.text) ?? 0,
                                'meal_allowance': double.tryParse(mealC.text) ?? 0,
                                'phone_allowance': double.tryParse(phoneC.text) ?? 0,
                                'ot_rate_per_hour': double.tryParse(otRateC.text) ?? 0,
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
    final gross = ((payslip['gross_salary'] ?? 0) as num).toDouble();
    final net = ((payslip['net_salary'] ?? 0) as num).toDouble();
    final base = ((payslip['base_salary'] ?? 0) as num).toDouble();
    final allowances = ((payslip['total_allowances'] ?? 0) as num).toDouble();
    final deductions = ((payslip['total_deductions'] ?? 0) as num).toDouble();
    final ot = ((payslip['overtime_pay'] ?? 0) as num).toDouble();
    final status = payslip['status'] ?? 'draft';

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
              const Text('Net Salary', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_formatMoney(net), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Earnings Section
        _buildPayslipSection(isDark, 'Earnings', AppColors.present, [
          _buildPayslipRow('Base Salary', _formatMoney(base), AppColors.present),
          _buildPayslipRow('Allowances', _formatMoney(allowances), AppColors.present),
          _buildPayslipRow('Overtime Pay', _formatMoney(ot), AppColors.present),
          const Divider(),
          _buildPayslipRow('Gross Salary', _formatMoney(gross), AppColors.primary, isBold: true),
        ]),

        const SizedBox(height: 12),

        // Deductions Section
        _buildPayslipSection(isDark, 'Deductions', AppColors.absent, [
          _buildPayslipRow('SSB (2%)', _formatMoney(base * 0.02), AppColors.absent),
          _buildPayslipRow('Income Tax', _formatMoney((payslip['tax'] ?? 0).toDouble()), AppColors.absent),
          _buildPayslipRow('Absent Deduction', _formatMoney((payslip['absent_deduction'] ?? 0).toDouble()), AppColors.absent),
          _buildPayslipRow('Salary Advance', _formatMoney((payslip['advance_deduction'] ?? 0).toDouble()), AppColors.warning),
          const Divider(),
          _buildPayslipRow('Total Deductions', _formatMoney(deductions), AppColors.absent, isBold: true),
        ]),

        const SizedBox(height: 20),

        // Download / Share PDF
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.document_download, size: 20),
                  label: const Text('Preview PDF'),
                  onPressed: () async {
                    try {
                      await PayslipPdfService.generateAndPreview(payslip, _selectedYear, _selectedMonth);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ PDF Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () async {
                  try {
                    await PayslipPdfService.sharePdf(payslip, _selectedYear, _selectedMonth);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Share Error: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                child: const Icon(Iconsax.share, size: 20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
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