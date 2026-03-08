import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Company Info
  final _companyNameController = TextEditingController();
  final _companyNameMmController = TextEditingController();
  String _businessType = 'retail';
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _stateRegion = 'Yangon Region';

  // Step 2: Contact
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 3: Verify
  final _codeController = TextEditingController();
  String? _devCode;

  // Step 4: Owner Setup
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  final _businessTypes = [
    {'value': 'manufacturing', 'label': 'Manufacturing (စက်ရုံ)'},
    {'value': 'retail', 'label': 'Retail (လက်လီ)'},
    {'value': 'fnb', 'label': 'Food & Beverage (စားသောက်ဆိုင်)'},
    {'value': 'service', 'label': 'Service (ဝန်ဆောင်မှု)'},
    {'value': 'technology', 'label': 'Technology (နည်းပညာ)'},
    {'value': 'construction', 'label': 'Construction (ဆောက်လုပ်ရေး)'},
    {'value': 'education', 'label': 'Education (ပညာရေး)'},
    {'value': 'healthcare', 'label': 'Healthcare (ကျန်းမာရေး)'},
    {'value': 'other', 'label': 'Other (အခြား)'},
  ];

  final _regions = [
    'Yangon Region', 'Mandalay Region', 'Sagaing Region', 'Bago Region',
    'Magway Region', 'Tanintharyi Region', 'Ayeyarwady Region',
    'Kachin State', 'Kayah State', 'Kayin State', 'Chin State',
    'Mon State', 'Rakhine State', 'Shan State', 'Naypyidaw',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _companyNameController.dispose();
    _companyNameMmController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  // Step 2 → Sign Up Company
  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _phoneController.text.isEmpty) {
      _showError('Email နှင့် Phone number ဖြည့်ပါ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.companySignUp({
        'name': _companyNameController.text.trim(),
        'name_mm': _companyNameMmController.text.trim(),
        'business_type': _businessType,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state_region': _stateRegion,
      });

      setState(() {
        _devCode = response['dev_verification_code'];
        _isLoading = false;
      });

      _showSuccess('Verification code sent!');
      _nextStep();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // Step 3 → Verify Code
  Future<void> _handleVerify() async {
    if (_codeController.text.isEmpty) {
      _showError('Verification code ဖြည့်ပါ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.verifyCompany(_emailController.text.trim(), _codeController.text.trim());

      setState(() => _isLoading = false);
      _showSuccess('Company verified!');
      _nextStep();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // Step 4 → Set Owner Password & Login
  Future<void> _handleSetPassword() async {
    if (_ownerNameController.text.isEmpty || _ownerPhoneController.text.isEmpty) {
      _showError('Name နှင့် Phone ဖြည့်ပါ');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.setOwnerPassword({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'owner_name': _ownerNameController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
      });

      // Login with the new credentials to update auth state
      final success = await ref.read(authProvider.notifier).adminLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccess('Account created! Welcome to Easy HR!');
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/');
      } else {
        _showError('Account created but login failed. Please login manually.');
        if (mounted) context.go('/login');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: _currentStep > 0 ? _prevStep : () => context.pop(),
        ),
        title: Text('Step ${_currentStep + 1} of 4'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${((_currentStep + 1) / 4 * 100).round()}%',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1CompanyInfo(),
                _buildStep2Contact(),
                _buildStep3Verify(),
                _buildStep4OwnerSetup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 1: Company Information
  // ============================================
  Widget _buildStep1CompanyInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Company Information', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('ကုမ္ပဏီအချက်အလက်ဖြည့်ပါ', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          const Text('Company Name (English) *'),
          const SizedBox(height: 8),
          TextField(
            controller: _companyNameController,
            decoration: const InputDecoration(hintText: 'e.g. ABC Company', prefixIcon: Icon(Iconsax.building, size: 20)),
          ),
          const SizedBox(height: 16),

          const Text('Company Name (Myanmar)'),
          const SizedBox(height: 8),
          TextField(
            controller: _companyNameMmController,
            decoration: const InputDecoration(hintText: 'e.g. ABC ကုမ္ပဏီ', prefixIcon: Icon(Iconsax.building_4, size: 20)),
          ),
          const SizedBox(height: 16),

          const Text('Business Type *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _businessType,
            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.category, size: 20)),
            items: _businessTypes.map((t) => DropdownMenuItem(
              value: t['value'],
              child: Text(t['label']!, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (v) => setState(() => _businessType = v!),
          ),
          const SizedBox(height: 16),

          const Text('Address'),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Office address', prefixIcon: Icon(Iconsax.location, size: 20)),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(hintText: 'Yangon'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('State/Region'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _stateRegion,
                      isExpanded: true,
                      items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _stateRegion = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_companyNameController.text.isEmpty) {
                  _showError('Company name ဖြည့်ပါ');
                  return;
                }
                _nextStep();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Next'), SizedBox(width: 8), Icon(Iconsax.arrow_right_3, size: 18)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 2: Contact Information
  // ============================================
  Widget _buildStep2Contact() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Contact Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('ဆက်သွယ်ရန်အချက်အလက်ဖြည့်ပါ', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          const Text('Email Address *'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'company@example.com',
              prefixIcon: Icon(Iconsax.sms, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text('Verification code ကို ဒီ email ကို ပို့ပါမယ်',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning)),
          const SizedBox(height: 20),

          const Text('Phone Number *'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '09xxxxxxxxx',
              prefixIcon: Icon(Iconsax.call, size: 20),
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign Up & Send Code'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 3: Verify Code
  // ============================================
  Widget _buildStep3Verify() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Verify Company', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Email ထဲသို့ ပို့ထားတဲ့ code ထည့်ပါ', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          // Dev Code Display
          if (_devCode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Iconsax.warning_2, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text('Development Mode', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: $_devCode',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                  ),
                ],
              ),
            ),

          const Text('Verification Code *'),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify'),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {}, // Resend code
              child: const Text('Resend Code'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 4: Owner Account Setup
  // ============================================
  Widget _buildStep4OwnerSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Owner Account', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('အကောင့်ပိုင်ရှင် အချက်အလက်ဖြည့်ပါ', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          const Text('Your Name *'),
          const SizedBox(height: 8),
          TextField(
            controller: _ownerNameController,
            decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Iconsax.user, size: 20)),
          ),
          const SizedBox(height: 16),

          const Text('Your Phone *'),
          const SizedBox(height: 8),
          TextField(
            controller: _ownerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '09xxxxxxxxx', prefixIcon: Icon(Iconsax.call, size: 20)),
          ),
          const SizedBox(height: 16),

          const Text('Password *'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Minimum 8 characters',
              prefixIcon: const Icon(Iconsax.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Confirm Password *'),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Re-enter password',
              prefixIcon: Icon(Iconsax.lock_1, size: 20),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSetPassword,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.tick_circle),
                        SizedBox(width: 8),
                        Text('Create Account & Login'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}