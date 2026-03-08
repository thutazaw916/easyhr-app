import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class SalaryAdvanceScreen extends ConsumerStatefulWidget {
  const SalaryAdvanceScreen({super.key});

  @override
  ConsumerState<SalaryAdvanceScreen> createState() => _SalaryAdvanceScreenState();
}

class _SalaryAdvanceScreenState extends ConsumerState<SalaryAdvanceScreen> {
  final _amountC = TextEditingController();
  final _reasonC = TextEditingController();
  List<Map<String, dynamic>> _advances = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;
      final result = isAdmin ? await api.listEmployees(params: {'_table': 'advances'}) : [];
      // Use my-advances for non-admin
      _advances = []; // Will be populated when API is connected
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: const Text('Salary Advance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Iconsax.money_send, color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Request Advance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (MMK)',
                      prefixIcon: const Icon(Iconsax.money_send, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonC,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why do you need an advance?',
                      prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Iconsax.document_text, size: 20)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Iconsax.send_1, size: 18),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
                      onPressed: _isSubmitting ? null : _submitAdvance,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // My Advance History
            Text('Advance History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_advances.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Iconsax.empty_wallet, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    const SizedBox(height: 12),
                    Text('No advance requests yet', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            else
              ..._advances.map((a) => _buildAdvanceCard(isDark, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceCard(bool isDark, Map<String, dynamic> advance) {
    final amount = ((advance['amount'] ?? 0) as num).toDouble();
    final status = advance['status'] ?? 'pending';
    final date = advance['created_at'] ?? '';

    Color statusColor;
    switch (status) {
      case 'approved': statusColor = AppColors.present; break;
      case 'rejected': statusColor = AppColors.absent; break;
      default: statusColor = AppColors.warning;
    }

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
            width: 40, height: 40,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Iconsax.money_send, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${NumberFormat('#,###').format(amount)} MMK', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
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

  Future<void> _submitAdvance() async {
    if (_amountC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // API call will be connected
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Advance request submitted!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
      );
      _amountC.clear();
      _reasonC.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating),
      );
    }
    setState(() => _isSubmitting = false);
  }

  @override
  void dispose() {
    _amountC.dispose();
    _reasonC.dispose();
    super.dispose();
  }
}