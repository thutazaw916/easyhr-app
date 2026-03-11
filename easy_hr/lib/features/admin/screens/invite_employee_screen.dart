import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class InviteEmployeeScreen extends ConsumerStatefulWidget {
  const InviteEmployeeScreen({super.key});

  @override
  ConsumerState<InviteEmployeeScreen> createState() => _InviteEmployeeScreenState();
}

class _InviteEmployeeScreenState extends ConsumerState<InviteEmployeeScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'employee';
  bool _isLoading = false;
  String? _lastInviteCode;
  List<dynamic> _invitations = [];

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.listInvitations();
      if (mounted) setState(() => _invitations = data);
    } catch (_) {}
  }

  Future<void> _sendInvite() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and phone'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.inviteEmployee({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
      });

      final code = result['invite_code'] ?? '';
      setState(() {
        _lastInviteCode = code;
        _isLoading = false;
      });
      _nameController.clear();
      _phoneController.clear();
      _loadInvitations();

      if (mounted) {
        _showInviteCodeDialog(code);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.toString().contains('already exists')
            ? 'This phone number is already registered'
            : 'Failed to send invitation';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showInviteCodeDialog(String code) {
    final lang = ref.read(languageProvider);
    final mm = lang == 'mm';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.present.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.tick_circle, color: AppColors.present, size: 22),
            ),
            const SizedBox(width: 12),
            Text(mm ? 'ဖိတ်ကြားချက် ပို့ပြီးပါပြီ' : 'Invitation Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mm ? 'ဝန်ထမ်းကို ဒီကုဒ်ပေးပါ:' : 'Share this code with the employee:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(mm ? 'ကူးယူပြီးပါပြီ' : 'Copied!'), duration: const Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Iconsax.copy, color: AppColors.primary, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mm ? '(၇ ရက်အတွင်း အသုံးပြုရပါမည်)' : '(Valid for 7 days)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(mm ? 'ပိတ်ရန်' : 'Close'),
          ),
        ],
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
        title: Text(mm ? 'ဝန်ထမ်း ဖိတ်ကြားရန်' : 'Invite Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: AppColors.info, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mm
                          ? 'ဖုန်းနံပါတ်နှင့် အမည်ထည့်ပြီး ဖိတ်ကြားကုဒ် ပို့ပေးပါ။ ဝန်ထမ်းက app မှ ကုဒ်ထည့်ပြီး ဝင်ရောက်နိုင်ပါသည်။'
                          : 'Enter phone and name to generate an invite code. Employee can join by entering the code in the app.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Name
            Text(mm ? 'အမည်' : 'Name', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: mm ? 'ဝန်ထမ်းအမည်' : 'Employee name',
                prefixIcon: const Icon(Iconsax.user, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Phone
            Text(mm ? 'ဖုန်းနံပါတ်' : 'Phone Number', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '09xxxxxxxxx',
                prefixIcon: const Icon(Iconsax.call, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Role
            Text(mm ? 'ရာထူး' : 'Role', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'employee', child: Text(mm ? 'ဝန်ထမ်း' : 'Employee')),
                    DropdownMenuItem(value: 'department_head', child: Text(mm ? 'ဌာနမှူး' : 'Department Head')),
                    DropdownMenuItem(value: 'hr_manager', child: Text(mm ? 'HR Manager' : 'HR Manager')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendInvite,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Iconsax.send_1),
                label: Text(mm ? 'ဖိတ်ကြားကုဒ် ပို့ရန်' : 'Send Invite Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Invitation History
            Text(mm ? 'ဖိတ်ကြားမှုများ' : 'Invitations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (_invitations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(mm ? 'ဖိတ်ကြားချက် မရှိသေးပါ' : 'No invitations yet', style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              ..._invitations.map((inv) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor(inv['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        inv['status'] == 'accepted' ? Iconsax.tick_circle : Iconsax.clock,
                        color: _statusColor(inv['status']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(inv['phone'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(inv['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (inv['status'] ?? 'pending').toString().toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(inv['status'])),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(inv['invite_code'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'accepted': return AppColors.present;
      case 'expired': return AppColors.error;
      default: return AppColors.warning;
    }
  }
}
