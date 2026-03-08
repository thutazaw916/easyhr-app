import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _plansData;
  List<dynamic> _paymentHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.getSubscription(),
        api.getPlans(),
        api.getPaymentHistory(),
      ]);
      setState(() {
        _subscription = results[0] as Map<String, dynamic>;
        _plansData = results[1] as Map<String, dynamic>;
        _paymentHistory = results[2] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'အစီအစဉ်နှင့် ငွေပေးချေမှု' : 'Plans & Billing'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Iconsax.warning_2, size: 48, color: AppColors.absent),
                  const SizedBox(height: 12),
                  Text(mm ? 'ဒေတာ ရယူ၍မရပါ' : 'Failed to load'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadData, child: Text(mm ? 'ပြန်ကြိုးစား' : 'Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCurrentPlan(isDark, mm),
                      const SizedBox(height: 24),
                      Text(mm ? 'အစီအစဉ်များ' : 'Available Plans',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._buildPlanCards(isDark, mm),
                      const SizedBox(height: 24),
                      Text(mm ? 'ငွေပေးချေမှု မှတ်တမ်း' : 'Payment History',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._buildPaymentHistory(isDark, mm),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentPlan(bool isDark, bool mm) {
    final plan = _subscription?['current_plan'] ?? {};
    final daysLeft = _subscription?['days_remaining'] ?? 0;
    final empCount = _subscription?['employee_count'] ?? 0;
    final maxEmp = _subscription?['max_employees'] ?? 0;
    final status = _subscription?['subscription_status'] ?? 'active';
    final isFree = plan['name'] == 'free';

    Color statusColor = status == 'active' ? AppColors.present : AppColors.absent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree
              ? [Colors.grey.shade700, Colors.grey.shade600]
              : [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mm ? (plan['label_mm'] ?? plan['label'] ?? 'Free') : (plan['label'] ?? 'Free'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(status.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isFree ? (mm ? 'အခမဲ့' : 'FREE') : '${_formatMMK(plan['price'] ?? 0)} / ${mm ? "လ" : "mo"}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(Iconsax.people5, '$empCount / $maxEmp', mm ? 'ဝန်ထမ်း' : 'Employees'),
              const SizedBox(width: 20),
              _buildMiniStat(Iconsax.calendar_1, '$daysLeft', mm ? 'ရက်ကျန်' : 'Days left'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPlanCards(bool isDark, bool mm) {
    final plans = (_plansData?['plans'] as List?) ?? [];
    final currentPlan = _subscription?['current_plan']?['name'] ?? 'free';

    return plans.map<Widget>((plan) {
      final isCurrent = plan['name'] == currentPlan;
      final isUpgrade = _planIndex(plan['name']) > _planIndex(currentPlan);
      final price = plan['price'] ?? 0;
      final isFree = price == 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mm ? (plan['label_mm'] ?? plan['label']) : plan['label'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isCurrent ? AppColors.primary : null),
                ),
                const Spacer(),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(mm ? 'လက်ရှိ' : 'Current', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFree ? (mm ? 'အခမဲ့' : 'FREE') : '${_formatMMK(price)} / ${mm ? "လ" : "month"}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(height: 4),
            Text('${mm ? "ဝန်ထမ်း" : "Up to"} ${plan['max_employees']} ${mm ? "ဦးအထိ" : "employees"}',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ...(plan['features'] as List? ?? []).map<Widget>((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Iconsax.tick_circle5, size: 16, color: isCurrent ? AppColors.primary : AppColors.present),
                const SizedBox(width: 8),
                Text(f.toString(), style: const TextStyle(fontSize: 13)),
              ]),
            )),
            if (isUpgrade) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPaymentSheet(plan, mm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(mm ? 'အဆင့်မြှင့်ရန်' : 'Upgrade'),
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  void _showPaymentSheet(Map<String, dynamic> plan, bool mm) {
    final methods = (_plansData?['payment_methods'] as List?) ?? [];
    String? selectedMethod;
    int months = 1;
    final txnController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final total = (plan['price'] ?? 0) * months;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(mm ? 'ငွေပေးချေရန်' : 'Payment', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${plan['label']} Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Duration
                Text(mm ? 'ကာလ' : 'Duration', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [1, 3, 6, 12].map((m) => Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => months = m),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: months == m ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Text('$m', style: TextStyle(fontWeight: FontWeight.bold, color: months == m ? Colors.white : Colors.black)),
                          Text(mm ? 'လ' : 'mo', style: TextStyle(fontSize: 10, color: months == m ? Colors.white70 : Colors.grey)),
                        ]),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(mm ? 'စုစုပေါင်း' : 'Total', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(_formatMMK(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment method
                Text(mm ? 'ငွေပေးချေနည်း' : 'Payment Method', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...methods.map((m) => RadioListTile<String>(
                  value: m['id'],
                  groupValue: selectedMethod,
                  onChanged: (v) => setSheetState(() => selectedMethod = v),
                  title: Text('${m['icon']} ${m['name']}'),
                  subtitle: Text(m['account'] ?? ''),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                )),
                const SizedBox(height: 12),

                // Transaction ID
                TextField(
                  controller: txnController,
                  decoration: InputDecoration(
                    labelText: mm ? 'Transaction ID (ချန်ယူ ID)' : 'Transaction ID',
                    hintText: mm ? 'ငွေလွှဲပြေစာ ID ထည့်ပါ' : 'Enter payment reference',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedMethod == null ? null : () => _submitPayment(plan, selectedMethod!, months, total, txnController.text, mm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(mm ? 'ငွေပေးချေမှု တင်ရန်' : 'Submit Payment', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitPayment(Map<String, dynamic> plan, String method, int months, int amount, String txnId, bool mm) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.submitPayment({
        'plan': plan['name'],
        'payment_method': method,
        'transaction_id': txnId,
        'amount': amount,
        'months': months,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mm ? (result['message_mm'] ?? 'တင်ပြီးပါပြီ!') : (result['message'] ?? 'Submitted!')),
          backgroundColor: AppColors.present,
        ));
        _loadData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mm ? 'အမှား ဖြစ်သွားပါတယ်' : 'Error submitting payment'), backgroundColor: AppColors.absent));
      }
    }
  }

  List<Widget> _buildPaymentHistory(bool isDark, bool mm) {
    if (_paymentHistory.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(mm ? 'ငွေပေးချေမှု မှတ်တမ်း မရှိသေးပါ' : 'No payment history yet',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
        ),
      ];
    }

    return _paymentHistory.map<Widget>((p) {
      final status = p['status'] ?? 'pending';
      Color statusColor;
      IconData statusIcon;
      switch (status) {
        case 'approved':
          statusColor = AppColors.present;
          statusIcon = Iconsax.tick_circle5;
          break;
        case 'rejected':
          statusColor = AppColors.absent;
          statusIcon = Iconsax.close_circle5;
          break;
        default:
          statusColor = AppColors.warning;
          statusIcon = Iconsax.clock;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${(p['plan'] ?? '').toString().toUpperCase()} Plan',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${p['payment_method'] ?? ''} | ${p['months'] ?? 1} ${mm ? "လ" : "mo"}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatMMK(p['amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  int _planIndex(String name) {
    const order = ['free', 'starter', 'business', 'enterprise'];
    return order.indexOf(name);
  }

  String _formatMMK(dynamic amount) {
    final num = (amount is int) ? amount : int.tryParse(amount.toString()) ?? 0;
    return '${num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} MMK';
  }
}
