import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

class PaymentWallScreen extends ConsumerWidget {
  final String? reason;

  const PaymentWallScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final sub = auth.subscription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('အစီအစဉ် အဆင့်မြှင့်ရန်'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: sub?.isExpired == true
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    sub?.isExpired == true ? Icons.lock_outline : Icons.info_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sub?.isExpired == true
                        ? 'သက်တမ်းကုန်ဆုံးသွားပါပြီ'
                        : 'အခပေးအစီအစဉ် လိုအပ်ပါသည်',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason ?? _getDefaultMessage(sub),
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (sub != null && !sub.isExpired && sub.daysRemaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sub.daysRemaining} ရက် ကျန်ပါသေးသည်',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plans
            _buildPlanCard(
              context,
              title: 'Starter',
              titleMm: 'စတင်',
              price: '49,000',
              features: [
                'ဝန်ထမ်း ၄၉ ဦးအထိ',
                'Leave Management',
                'Payroll Calculation',
              ],
              color: Colors.blue,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context,
              title: 'Business',
              titleMm: 'စီးပွားရေး',
              price: '99,000',
              features: [
                'ဝန်ထမ်း ၉၉ ဦးအထိ',
                'AI Chatbot',
                'Reports & Analytics',
              ],
              color: Colors.purple,
              isPopular: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context,
              title: 'Enterprise',
              titleMm: 'လုပ်ငန်းကြီး',
              price: '199,000',
              features: [
                'ဝန်ထမ်းအကန့်အသတ်မရှိ',
                'Priority Support',
                'Custom Integrations',
              ],
              color: Colors.amber.shade700,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Payment Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ငွေပေးချေနည်း',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _paymentMethodRow('KBZPay', '09971489502', Icons.phone_android),
                  _paymentMethodRow('WavePay', '09971489502', Icons.phone_android),
                  _paymentMethodRow('KBZ Bank', '06651199910919301', Icons.account_balance),
                  const SizedBox(height: 12),
                  Text(
                    'ငွေလွှဲပြီးပါက Screenshot ကို Admin ထံပို့ပေးပါ။ ၂၄ နာရီအတွင်း အတည်ပြုပေးပါမည်။',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getDefaultMessage(SubscriptionModel? sub) {
    if (sub?.isExpired == true) {
      return 'ဆက်လက်အသုံးပြုရန် အစီအစဉ်တစ်ခုကို ရွေးချယ်ပါ။';
    }
    return 'ဤလုပ်ဆောင်ချက်အတွက် အခပေးအစီအစဉ် လိုအပ်ပါသည်။';
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String titleMm,
    required String price,
    required List<String> features,
    required Color color,
    bool isPopular = false,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$title ($titleMm)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$price MMK / လ',
            style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: color),
                const SizedBox(width: 8),
                Text(f, style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _paymentMethodRow(String name, String account, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$name: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(account, style: const TextStyle(fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
