import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class EditEmployeeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> employee;
  const EditEmployeeScreen({super.key, required this.employee});

  @override
  ConsumerState<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends ConsumerState<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _phoneC;
  late final TextEditingController _emailC;
  late final TextEditingController _positionC;
  late final TextEditingController _salaryC;
  late final TextEditingController _nrcC;
  late final TextEditingController _codeC;
  late String _role;
  late String _gender;
  String? _joinDate;
  bool _isLoading = false;

  final _commonPositions = [
    'Admin', 'Sales', 'Marketing', 'Accountant', 'Cashier',
    'Driver', 'Security', 'Cleaner', 'Receptionist', 'Manager',
    'Supervisor', 'Technician', 'Engineer', 'Designer', 'Developer',
    'Waiter', 'Chef', 'Delivery', 'Warehouse', 'Quality Control',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameC = TextEditingController(text: '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim());
    _phoneC = TextEditingController(text: e['phone'] ?? '');
    _emailC = TextEditingController(text: e['email'] ?? '');
    _positionC = TextEditingController(text: e['position'] ?? e['position_name'] ?? '');
    _salaryC = TextEditingController(text: e['base_salary']?.toString() ?? '');
    _nrcC = TextEditingController(text: e['nrc_number'] ?? '');
    _codeC = TextEditingController(text: e['employee_code'] ?? '');
    _role = e['role'] ?? 'employee';
    _gender = e['gender'] ?? 'male';
    _joinDate = e['join_date'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'ဝန်ထမ်းပြင်ဆင်ရန်' : 'Edit Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              _buildField(isDark, mm ? 'အမည်' : 'Full Name', _nameC, Iconsax.user),
              const SizedBox(height: 12),

              // Phone
              _buildField(isDark, mm ? 'ဖုန်းနံပါတ်' : 'Phone', _phoneC, Iconsax.call,
                keyboardType: TextInputType.phone),
              const SizedBox(height: 12),

              // Email
              _buildField(isDark, mm ? 'အီးမေးလ်' : 'Email', _emailC, Iconsax.sms,
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),

              // Employee Code
              _buildField(isDark, mm ? 'ဝန်ထမ်းကုဒ်' : 'Employee Code', _codeC, Iconsax.hashtag),
              const SizedBox(height: 12),

              // NRC
              _buildField(isDark, mm ? 'မှတ်ပုံတင်' : 'NRC Number', _nrcC, Iconsax.card),
              const SizedBox(height: 12),

              // Gender
              _buildDropdown(isDark, mm ? 'ကျား/မ' : 'Gender', _gender, [
                {'value': 'male', 'label': mm ? 'ကျား' : 'Male'},
                {'value': 'female', 'label': mm ? 'မ' : 'Female'},
              ], (v) => setState(() => _gender = v ?? 'male')),
              const SizedBox(height: 12),

              // Role
              _buildDropdown(isDark, mm ? 'အခန်းကဏ္ဍ' : 'Role', _role, [
                {'value': 'employee', 'label': mm ? 'ဝန်ထမ်း' : 'Employee'},
                {'value': 'hr_manager', 'label': mm ? 'HR မန်နေဂျာ' : 'HR Manager'},
                {'value': 'department_head', 'label': mm ? 'ဌာနမှူး' : 'Dept Head'},
              ], (v) => setState(() => _role = v ?? 'employee')),
              const SizedBox(height: 12),

              // Position
              _buildField(isDark, mm ? 'ရာထူး' : 'Position / Job Title', _positionC, Iconsax.briefcase),
              if (_positionC.text.isEmpty)
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: _commonPositions.take(10).map((p) => ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _positionC.text = p),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              const SizedBox(height: 12),

              // Join Date
              Text(mm ? 'အလုပ်စဝင်သည့်နေ့' : 'Join Date', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context, initialDate: _joinDate != null ? DateTime.tryParse(_joinDate!) ?? DateTime.now() : DateTime.now(),
                    firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setState(() => _joinDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                  ),
                  child: Row(children: [
                    Icon(Iconsax.calendar, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    const SizedBox(width: 12),
                    Text(_joinDate ?? (mm ? 'ရွေးချယ်ပါ' : 'Select date'),
                      style: TextStyle(color: _joinDate != null ? null : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Salary
              _buildField(isDark, mm ? 'အခြေခံလစာ (ကျပ်)' : 'Base Salary (MMK)', _salaryC, Iconsax.money_send,
                keyboardType: TextInputType.number),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Iconsax.tick_circle, size: 20),
                  label: Text(_isLoading ? (mm ? 'သိမ်းနေပါသည်...' : 'Saving...') : (mm ? 'သိမ်းဆည်းရန်' : 'Save Changes')),
                  onPressed: _isLoading ? null : _save,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(bool isDark, String label, TextEditingController controller, IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown(bool isDark, String label, String value, List<Map<String, String>> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
        items: items.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final lang = ref.read(languageProvider);
      final mm = lang == 'mm';
      final nameParts = _nameC.text.trim().split(' ');
      final data = <String, dynamic>{
        'first_name': nameParts.first,
        'role': _role,
        'gender': _gender,
      };
      if (nameParts.length > 1) data['last_name'] = nameParts.sublist(1).join(' ');
      if (_phoneC.text.trim().isNotEmpty) data['phone'] = _phoneC.text.trim();
      if (_emailC.text.trim().isNotEmpty) data['email'] = _emailC.text.trim();
      if (_positionC.text.trim().isNotEmpty) data['position'] = _positionC.text.trim();
      if (_codeC.text.trim().isNotEmpty) data['employee_code'] = _codeC.text.trim();
      if (_nrcC.text.trim().isNotEmpty) data['nrc_number'] = _nrcC.text.trim();
      if (_joinDate != null) data['join_date'] = _joinDate!;
      if (_salaryC.text.trim().isNotEmpty) data['base_salary'] = _salaryC.text.trim();

      await api.updateEmployee(widget.employee['id'], data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mm ? '✅ ပြင်ဆင်ပြီးပါပြီ!' : '✅ Employee updated!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error';
        if (e is DioException) {
          final data = e.response?.data;
          errorMsg = data is Map<String, dynamic> ? data['message']?.toString() ?? 'Update failed' : 'Update failed';
        } else {
          errorMsg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMsg'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
        );
      }
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  void dispose() {
    _nameC.dispose(); _phoneC.dispose(); _emailC.dispose();
    _positionC.dispose(); _salaryC.dispose(); _nrcC.dispose(); _codeC.dispose();
    super.dispose();
  }
}
