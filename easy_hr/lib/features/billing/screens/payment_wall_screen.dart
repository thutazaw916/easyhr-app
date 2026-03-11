import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class PaymentWallScreen extends ConsumerStatefulWidget {
  final String? reason;
  const PaymentWallScreen({super.key, this.reason});

  @override
  ConsumerState<PaymentWallScreen> createState() => _PaymentWallScreenState();
}

class _PaymentWallScreenState extends ConsumerState<PaymentWallScreen> {
  String? _selectedPlan;
  File? _screenshotFile;
  bool _isUploading = false;

  final _plans = [
    {'key': 'starter', 'title': 'Starter (စတင်)', 'price': '49,000', 'color': Colors.blue,
      'features': ['ဝန်ထမ်း ၄၉ ဦးအထိ', 'Leave Management', 'Payroll Calculation']},
    {'key': 'business', 'title': 'Business (စီးပွားရေး)', 'price': '99,000', 'color': Colors.purple,
      'features': ['ဝန်ထမ်း ၉၉ ဦးအထိ', 'AI Chatbot', 'Reports & Analytics'], 'popular': true},
    {'key': 'enterprise', 'title': 'Enterprise (လုပ်ငန်းကြီး)', 'price': '199,000', 'color': Colors.amber.shade700,
      'features': ['ဝန်ထမ်းအကန့်အသတ်မရှိ', 'Priority Support', 'Custom Integrations']},
  ];

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() { _screenshotFile = File(picked.path); });
  }

  Future<void> _submitPayment() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အစီအစဉ်တစ်ခု ရွေးချယ်ပါ'), backgroundColor: AppColors.warning));
      return;
    }
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ငွေလွှဲ Screenshot ထည့်ပါ'), backgroundColor: AppColors.warning));
      return;
    }
    setState(() => _isUploading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final url = await api.uploadPaymentScreenshot(_screenshotFile!.path);
      final plan = _plans.firstWhere((p) => p['key'] == _selectedPlan);
      await api.submitPayment({
        'plan': _selectedPlan,
        'amount': int.parse((plan['price'] as String).replaceAll(',', '')),
        'screenshot_url': url,
        'payment_method': 'mobile_banking',
      });
      setState(() => _isUploading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Iconsax.tick_circle5, color: AppColors.present, size: 28), SizedBox(width: 8), Text('တင်ပြီးပါပြီ')]),
            content: const Text('ငွေလွှဲ Screenshot တင်ပြီးပါပြီ။\n\nAdmin မှ ၂၄ နာရီအတွင်း စစ်ဆေးပြီး အတည်ပြုပေးပါမည်။'),
            actions: [TextButton(onPressed: () { Navigator.pop(ctx); context.go('/'); }, child: const Text('အိုကေ'))],
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final sub = auth.subscription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('အစီအစဉ် အဆင့်မြှင့်ရန်'),
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () {
          if (GoRouter.of(context).canPop()) context.pop(); else context.go('/');
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(sub, isDark),
            const SizedBox(height: 24),

            // Step 1
            Text('၁။ အစီအစဉ် ရွေးချယ်ပါ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            ..._plans.map((p) => _buildPlanTile(p, isDark)),

            const SizedBox(height: 20),

            // Step 2
            Text('၂။ ငွေလွှဲပါ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            _buildPaymentInfo(isDark),

            const SizedBox(height: 20),

            // Step 3
            Text('၃။ ငွေလွှဲ Screenshot တင်ပါ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            _buildScreenshotArea(isDark),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitPayment,
                icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.send_1),
                label: Text(_isUploading ? 'တင်နေသည်...' : 'Screenshot တင်မည်'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SubscriptionModel? sub, bool isDark) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: sub?.isExpired == true ? [Colors.red.shade400, Colors.red.shade600] : [Colors.orange.shade400, Colors.orange.shade600]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Icon(sub?.isExpired == true ? Iconsax.lock : Iconsax.info_circle, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        Text(sub?.isExpired == true ? 'သက်တမ်းကုန်ဆုံးသွားပါပြီ' : 'အခပေးအစီအစဉ် လိုအပ်ပါသည်',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.reason ?? (sub?.isExpired == true ? 'ဆက်လက်အသုံးပြုရန် အစီအစဉ်တစ်ခုကို ရွေးချယ်ပါ။' : 'ဤလုပ်ဆောင်ချက်အတွက် အခပေးအစီအစဉ် လိုအပ်ပါသည်။'),
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), textAlign: TextAlign.center),
        if (sub != null && !sub.isExpired && sub.daysRemaining > 0)
          Padding(padding: const EdgeInsets.only(top: 12), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${sub.daysRemaining} ရက် ကျန်ပါသေးသည်', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          )),
      ]),
    );
  }

  Widget _buildPlanTile(Map<String, dynamic> plan, bool isDark) {
    final color = plan['color'] as Color;
    final isSelected = _selectedPlan == plan['key'];
    final features = plan['features'] as List<String>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan['key'] as String),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : (isDark ? Colors.grey.shade900 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), width: isSelected ? 2.5 : 1),
          ),
          child: Row(children: [
            Container(width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? color : Colors.grey, width: 2), color: isSelected ? color : Colors.transparent),
              child: isSelected ? const Icon(Iconsax.tick_square, size: 16, color: Colors.white) : null),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(plan['title'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                if (plan['popular'] == true) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 10)))],
              ]),
              Text('${plan['price']} MMK / လ', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...features.map((f) => Row(children: [Icon(Iconsax.tick_circle5, size: 14, color: color), const SizedBox(width: 6), Text(f, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))])),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(bool isDark) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _payRow('KBZPay', '09971489502', Iconsax.mobile),
        _payRow('WavePay', '09971489502', Iconsax.mobile),
        _payRow('KBZ Bank', '06651199910919301', Iconsax.bank),
      ]),
    );
  }

  Widget _payRow(String name, String acc, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8),
      Text('$name: ', style: const TextStyle(fontWeight: FontWeight.w600)),
      Expanded(child: Text(acc, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
      GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: acc)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name copied'), duration: const Duration(seconds: 1))); },
        child: const Icon(Iconsax.copy, size: 16, color: Colors.grey)),
    ]));
  }

  Widget _buildScreenshotArea(bool isDark) {
    return GestureDetector(
      onTap: _pickScreenshot,
      child: Container(
        width: double.infinity,
        height: _screenshotFile != null ? null : 150,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _screenshotFile != null ? AppColors.present : (isDark ? Colors.grey.shade600 : Colors.grey.shade300), width: _screenshotFile != null ? 2 : 1),
        ),
        child: _screenshotFile != null
            ? Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_screenshotFile!, width: double.infinity, fit: BoxFit.cover)),
                Positioned(top: 8, right: 8, child: GestureDetector(
                  onTap: () => setState(() => _screenshotFile = null),
                  child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Iconsax.close_circle, color: Colors.white, size: 18)))),
                Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.present, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Iconsax.tick_square, color: Colors.white, size: 14), SizedBox(width: 4), Text('ရွေးပြီး', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]))),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Iconsax.image, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Screenshot ထည့်ရန် နှိပ်ပါ', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                Text('PNG, JPG ဖိုင်များ ရွေးချယ်နိုင်ပါသည်', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ]),
      ),
    );
  }
}
