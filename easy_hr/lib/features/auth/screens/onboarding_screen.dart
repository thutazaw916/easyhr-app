import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final String idToken;
  final String email;
  final String name;
  final String? photoUrl;

  const OnboardingScreen({
    super.key,
    required this.idToken,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _businessType = 'retail';

  final _businessTypes = [
    {'value': 'manufacturing', 'label': 'ထုတ်လုပ်ရေး (Manufacturing)'},
    {'value': 'retail', 'label': 'လက်လီရောင်းချ (Retail)'},
    {'value': 'fnb', 'label': 'စားသောက်ဆိုင် (F&B)'},
    {'value': 'service', 'label': 'ဝန်ဆောင်မှု (Service)'},
    {'value': 'technology', 'label': 'နည်းပညာ (Technology)'},
    {'value': 'construction', 'label': 'ဆောက်လုပ်ရေး (Construction)'},
    {'value': 'education', 'label': 'ပညာရေး (Education)'},
    {'value': 'healthcare', 'label': 'ကျန်းမာရေး (Healthcare)'},
    {'value': 'other', 'label': 'အခြား (Other)'},
  ];

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _ownerNameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).onboardCompany({
      'id_token': widget.idToken,
      'company_name': _companyNameController.text.trim(),
      'business_type': _businessType,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      'owner_name': _ownerNameController.text.trim(),
    });

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ကုမ္ပဏီ အချက်အလက်'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Center(
                child: Column(
                  children: [
                    if (widget.photoUrl != null)
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(widget.photoUrl!),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'မင်္ဂလာပါ ${widget.name}!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎉 ၃၀ ရက် အခမဲ့ Trial',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'ကုမ္ပဏီအမည် *',
                  hintText: 'e.g. ABC Company',
                  prefixIcon: Icon(Iconsax.building),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'ကုမ္ပဏီအမည် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),

              // Business Type
              DropdownButtonFormField<String>(
                value: _businessType,
                decoration: const InputDecoration(
                  labelText: 'လုပ်ငန်းအမျိုးအစား *',
                  prefixIcon: Icon(Iconsax.category),
                ),
                items: _businessTypes.map((bt) => DropdownMenuItem(
                  value: bt['value'],
                  child: Text(bt['label']!, style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) => setState(() => _businessType = v ?? 'retail'),
              ),
              const SizedBox(height: 16),

              // Owner Name
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'ပိုင်ရှင်အမည် *',
                  hintText: 'e.g. Aung Aung',
                  prefixIcon: Icon(Iconsax.user),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'အမည် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'ဖုန်းနံပါတ် *',
                  hintText: '09xxxxxxxxx',
                  prefixIcon: Icon(Iconsax.call),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'ဖုန်းနံပါတ် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),

              // Address (optional)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'လိပ်စာ',
                  hintText: 'No. 123, Bogyoke Road',
                  prefixIcon: Icon(Iconsax.location),
                ),
              ),
              const SizedBox(height: 16),

              // City (optional)
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'မြို့',
                  hintText: 'Yangon',
                  prefixIcon: Icon(Iconsax.buildings),
                ),
              ),
              const SizedBox(height: 32),

              // Error
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
                ),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('စတင်သုံးမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
