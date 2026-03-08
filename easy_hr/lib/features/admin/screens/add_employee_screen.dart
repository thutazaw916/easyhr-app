import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _codeC = TextEditingController();
  final _salaryC = TextEditingController();
  final _nrcC = TextEditingController();
  final _positionC = TextEditingController();
  String _role = 'employee';
  String _gender = 'male';
  String? _joinDate;
  bool _isLoading = false;
  bool _showPositionSuggestions = false;

  final _commonPositions = [
    'Admin', 'Sales', 'Marketing', 'Accountant', 'Cashier',
    'Driver', 'Security', 'Cleaner', 'Receptionist', 'Manager',
    'Supervisor', 'Technician', 'Engineer', 'Designer', 'Developer',
    'Waiter', 'Chef', 'Delivery', 'Warehouse', 'Quality Control',
  ];

  List<String> get _filteredPositions {
    final query = _positionC.text.toLowerCase();
    if (query.isEmpty) return _commonPositions;
    return _commonPositions.where((p) => p.toLowerCase().contains(query)).toList();
  }

  // Myanmar phone number validation
  bool _isValidMyanmarPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    // Myanmar phone formats:
    // 09xxxxxxxxx (9-11 digits after 09)
    // +959xxxxxxxxx
    // 959xxxxxxxxx
    // 01xxxxxxx (Yangon landline)
    // 02xxxxxxx (Mandalay landline)
    final patterns = [
      RegExp(r'^09\d{7,9}$'),           // 09 + 7-9 digits
      RegExp(r'^\+959\d{7,9}$'),        // +959 + 7-9 digits
      RegExp(r'^959\d{7,9}$'),          // 959 + 7-9 digits
      RegExp(r'^0[1-9]\d{6,8}$'),       // Landline 0X + 6-8 digits
    ];
    return patterns.any((p) => p.hasMatch(cleaned));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';
    final s = AppStrings.get(lang);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'ဝန်ထမ်းအသစ်ထည့်ရန်' : 'Add Employee'),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showPositionSuggestions = false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Iconsax.user, size: 40, color: AppColors.primary),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Iconsax.camera, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // === Personal Info ===
                _sectionTitle(mm ? 'ကိုယ်ရေးအချက်အလက်' : 'Personal Info'),
                const SizedBox(height: 12),

                // Full Name (single field)
                _buildField(isDark, mm ? 'အမည် *' : 'Full Name *', _nameC, Iconsax.user,
                  hintText: mm ? 'ဥပမာ: မောင်မောင်' : 'e.g. Mg Mg',
                  validator: (v) => v!.trim().isEmpty ? (mm ? 'အမည်ဖြည့်ပါ' : 'Name required') : null),
                const SizedBox(height: 12),

                // Phone (Required) - Myanmar validation
                _buildField(isDark, mm ? 'ဖုန်းနံပါတ် *' : 'Phone Number *', _phoneC, Iconsax.call,
                  keyboardType: TextInputType.phone,
                  hintText: mm ? '09xxxxxxxxx' : '09xxxxxxxxx',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return mm ? 'ဖုန်းနံပါတ်ဖြည့်ပါ' : 'Phone required';
                    if (!_isValidMyanmarPhone(v.trim())) {
                      return mm ? 'မြန်မာဖုန်းနံပါတ် မှန်ကန်စွာ ဖြည့်ပါ' : 'Enter valid Myanmar phone number';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mm ? '* ဝန်ထမ်းသည် ဤဖုန်းနံပါတ်ဖြင့် OTP login ဝင်ရောက်ပါမည်' : '* Employee will use this phone for OTP login',
                        style: const TextStyle(fontSize: 11, color: AppColors.info, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 2),
                      Text(mm ? '  ပုံစံ: 09xxx, +959xxx, 01xxx (Yangon), 02xxx (Mandalay)' : '  Formats: 09xxx, +959xxx, 01xxx, 02xxx',
                        style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // NRC
                _buildField(isDark, mm ? 'မှတ်ပုံတင်အမှတ်' : 'NRC Number', _nrcC, Iconsax.card, hintText: '12/xxx(N)xxxxxx'),
                const SizedBox(height: 12),

                // Gender
                _buildDropdown(isDark, mm ? 'ကျား/မ' : 'Gender', _gender, [
                  {'value': 'male', 'label': mm ? 'ကျား' : 'Male'},
                  {'value': 'female', 'label': mm ? 'မ' : 'Female'},
                ], (v) => setState(() => _gender = v ?? 'male')),
                const SizedBox(height: 12),

                // Employee Code
                _buildField(isDark, mm ? 'ဝန်ထမ်းကုဒ်' : 'Employee Code', _codeC, Iconsax.hashtag,
                  hintText: mm ? 'အလိုအလျောက်ထုတ်ပေးပါမည်' : 'Auto-generated if empty'),

                const SizedBox(height: 24),

                // === Work Info ===
                _sectionTitle(mm ? 'အလုပ်အချက်အလက်' : 'Work Info'),
                const SizedBox(height: 12),

                // Role
                _buildDropdown(isDark, mm ? 'စနစ်အခန်းကဏ္ဍ' : 'System Role', _role, [
                  {'value': 'employee', 'label': mm ? 'ဝန်ထမ်း' : 'Employee'},
                  {'value': 'hr_manager', 'label': mm ? 'HR မန်နေဂျာ' : 'HR Manager'},
                  {'value': 'department_head', 'label': mm ? 'ဌာနမှူး' : 'Department Head'},
                ], (v) => setState(() => _role = v ?? 'employee')),
                const SizedBox(height: 12),

                // Position
                _sectionLabel(mm ? 'ရာထူး / Position *' : 'Position / Job Title *'),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _positionC,
                      onTap: () => setState(() => _showPositionSuggestions = true),
                      onChanged: (_) => setState(() => _showPositionSuggestions = true),
                      decoration: InputDecoration(
                        hintText: mm ? 'ရာထူး ရိုက်ထည့်ပါ (ဥပမာ: Sales, Admin, Driver...)' : 'Type position (e.g. Sales, Admin, Driver...)',
                        prefixIcon: const Icon(Iconsax.briefcase, size: 20),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    if (_showPositionSuggestions && _filteredPositions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredPositions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          itemBuilder: (context, index) {
                            final pos = _filteredPositions[index];
                            return InkWell(
                              onTap: () {
                                _positionC.text = pos;
                                setState(() => _showPositionSuggestions = false);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  Icon(Iconsax.briefcase, size: 16, color: AppColors.primary.withOpacity(0.6)),
                                  const SizedBox(width: 10),
                                  Text(pos, style: const TextStyle(fontSize: 14)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Join Date
                _sectionLabel(mm ? 'အလုပ်စဝင်သည့်နေ့' : 'Join Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context, initialDate: DateTime.now(),
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
                        style: TextStyle(color: _joinDate != null ? null : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 15)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Salary
                _buildField(isDark, mm ? 'အခြေခံလစာ (ကျပ်)' : 'Base Salary (MMK)', _salaryC, Iconsax.money_send,
                  keyboardType: TextInputType.number, hintText: mm ? 'ရွေးချယ်စရာ' : 'Optional'),

                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.user_add, size: 20),
                    label: Text(_isLoading ? (mm ? 'ထည့်နေပါသည်...' : 'Adding...') : (mm ? 'ဝန်ထမ်းထည့်ရန်' : 'Add Employee')),
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500));

  Widget _buildField(bool isDark, String label, TextEditingController controller, IconData icon, {
    TextInputType? keyboardType, String? Function(String?)? validator, String? hintText,
  }) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      decoration: InputDecoration(
        labelText: label, hintText: hintText, prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.absent, width: 1)),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _showPositionSuggestions = false; });
    try {
      final api = ref.read(apiServiceProvider);
      final lang = ref.read(languageProvider);
      final mm = lang == 'mm';
      final data = <String, dynamic>{
        'first_name': _nameC.text.trim(),
        'phone': _phoneC.text.trim(),
        'role': _role,
        'gender': _gender,
      };
      if (_positionC.text.isNotEmpty) data['position'] = _positionC.text.trim();
      if (_codeC.text.isNotEmpty) data['employee_code'] = _codeC.text.trim();
      if (_joinDate != null) data['join_date'] = _joinDate!;
      if (_salaryC.text.isNotEmpty) data['base_salary'] = _salaryC.text.trim();
      if (_nrcC.text.isNotEmpty) data['nrc_number'] = _nrcC.text.trim();

      await api.addEmployee(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mm ? '✅ ဝန်ထမ်းအသစ်ထည့်ပြီးပါပြီ!' : '✅ Employee added!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final lang = ref.read(languageProvider);
        final mm = lang == 'mm';
        String errorMsg;
        if (e is DioException) {
          final status = e.response?.statusCode;
          final data = e.response?.data;
          final backendMsg = data is Map<String, dynamic> ? data['message']?.toString() : null;
          if (status == 409) {
            errorMsg = mm ? 'ဤဖုန်းနံပါတ်ဖြင့် ဝန်ထမ်း ရှိပြီးသားဖြစ်ပါသည်' : 'Employee with this phone already exists.';
          } else if (status == 400 && backendMsg != null && backendMsg.contains('Employee limit')) {
            errorMsg = mm ? 'ဝန်ထမ်းအရေအတွက် ပြည့်နေပါပြီ။ Plan အဆင့်မြှင့်ပါ။' : 'Employee limit reached. Upgrade your plan.';
          } else if (status == 403) {
            errorMsg = mm ? 'Owner / HR Manager သာ ဝန်ထမ်းထည့်နိုင်ပါသည်' : 'Only Owner/HR can add employees.';
          } else if (backendMsg != null) {
            errorMsg = backendMsg;
          } else {
            errorMsg = mm ? 'အမှားတစ်ခု ဖြစ်ပေါ်ခဲ့သည်' : 'An error occurred.';
          }
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
    _nameC.dispose(); _phoneC.dispose(); _codeC.dispose();
    _salaryC.dispose(); _nrcC.dispose(); _positionC.dispose();
    super.dispose();
  }
}