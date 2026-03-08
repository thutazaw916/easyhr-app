import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _filterRole = 'all';
  String _filterDept = 'all';
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.listEmployees();
      debugPrint('📋 Employee API result: $result');
      debugPrint('📋 Employees count: ${(result['employees'] as List?)?.length ?? 0}');
      setState(() {
        _employees = List<Map<String, dynamic>>.from(result['employees'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Employee load error: $e');
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    return _employees.where((e) {
      final search = _searchController.text.toLowerCase();
      final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.toLowerCase();
      final code = (e['employee_code'] ?? '').toString().toLowerCase();
      final matchSearch = search.isEmpty || name.contains(search) || code.contains(search);
      final matchRole = _filterRole == 'all' || e['role'] == _filterRole;
      return matchSearch && matchRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.user_add),
            onPressed: () async {
              final result = await context.push('/admin/employees/add');
              if (result == true) _loadEmployees();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or employee code...',
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); setState(() {}); })
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Owner', 'owner'),
                _buildFilterChip('HR', 'hr_manager'),
                _buildFilterChip('Dept Head', 'department_head'),
                _buildFilterChip('Employee', 'employee'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Employee count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filteredEmployees.length} employees', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Employee List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.warning_2, size: 48, color: AppColors.absent),
                            const SizedBox(height: 12),
                            Text('Failed to load employees', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _loadEmployees, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredEmployees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.people5, size: 64, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                const SizedBox(height: 16),
                                Text('No employees found', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Iconsax.user_add, size: 18),
                                  label: const Text('Add Employee'),
                                  onPressed: () async {
                                    final result = await context.push('/admin/employees/add');
                                    if (result == true) _loadEmployees();
                                  },
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEmployees,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) => _buildEmployeeCard(context, isDark, _filteredEmployees[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        onSelected: (_) => setState(() => _filterRole = value),
        selectedColor: AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, bool isDark, Map<String, dynamic> employee) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final code = employee['employee_code'] ?? '';
    final role = employee['role'] ?? 'employee';
    final isActive = employee['is_active'] ?? true;
    final phone = employee['phone'] ?? '';
    final dept = employee['department_name'] ?? '';
    final position = employee['position_name'] ?? '';
    final photo = employee['profile_photo_url'];

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'owner': roleColor = AppColors.primary; roleLabel = 'Owner'; break;
      case 'hr_manager': roleColor = AppColors.accent; roleLabel = 'HR Manager'; break;
      case 'department_head': roleColor = AppColors.info; roleLabel = 'Dept Head'; break;
      default: roleColor = AppColors.present; roleLabel = 'Employee';
    }

    return GestureDetector(
      onTap: () => _showEmployeeDetail(context, isDark, employee),
      child: Container(
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
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.1),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18)) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name.isEmpty ? 'Unnamed' : name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(roleLabel, style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (code.isNotEmpty) ...[
                        Icon(Iconsax.hashtag, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        const SizedBox(width: 2),
                        Text(code, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                        const SizedBox(width: 12),
                      ],
                      if (dept.isNotEmpty) ...[
                        Icon(Iconsax.building, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        const SizedBox(width: 2),
                        Flexible(child: Text(dept, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                  if (position.isNotEmpty || phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (position.isNotEmpty) ...[
                          Icon(Iconsax.briefcase, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          const SizedBox(width: 2),
                          Text(position, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                          const SizedBox(width: 12),
                        ],
                        if (phone.isNotEmpty) ...[
                          Icon(Iconsax.call, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          const SizedBox(width: 2),
                          Text(phone, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.absent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('Inactive', style: TextStyle(fontSize: 10, color: AppColors.absent)),
              ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetail(BuildContext context, bool isDark, Map<String, dynamic> employee) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final role = employee['role'] ?? 'employee';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              Text(role.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _detailRow(isDark, Iconsax.hashtag, 'Employee Code', employee['employee_code'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.sms, 'Email', employee['email'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.call, 'Phone', employee['phone'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.building, 'Department', employee['department_name'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.briefcase, 'Position', employee['position_name'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.calendar, 'Joined', employee['join_date'] ?? 'N/A'),
              _detailRow(isDark, Iconsax.money_send, 'Salary', employee['base_salary'] != null ? '${employee['base_salary']} MMK' : 'Not set'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Iconsax.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () { Navigator.pop(ctx); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Iconsax.chart_square, size: 18),
                      label: const Text('Report'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}