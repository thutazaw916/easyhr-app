import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../../core/theme/app_theme.dart';

class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  ConsumerState<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _firebaseAuth = FirebasePhoneAuthService();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String? _statusMessage;
  bool _useFirebase = true; // true = Firebase SMS, false = backend dev OTP
  String? _devOtp;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSendingOtp = true;
      _statusMessage = null;
    });

    if (_useFirebase) {
      // Firebase Phone Auth - sends real SMS
      await _firebaseAuth.sendOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _otpSent = true;
              _isSendingOtp = false;
              _statusMessage = 'OTP sent to your phone!';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isSendingOtp = false;
              _statusMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        },
        onAutoVerified: (credential) async {
          // Auto-verified (Android) - sign in directly
          if (mounted) {
            setState(() => _statusMessage = 'Auto-verifying...');
          }
          await _signInWithFirebaseCredential(credential);
        },
      );
    } else {
      // Fallback: backend dev OTP
      try {
        final response = await ref.read(authProvider.notifier).requestOtp(phone);
        setState(() {
          _otpSent = true;
          _isSendingOtp = false;
          _devOtp = response['dev_otp'];
        });
      } catch (e) {
        setState(() => _isSendingOtp = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${ref.read(authProvider).error}'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isVerifying = true);

    if (_useFirebase) {
      try {
        final idToken = await _firebaseAuth.verifyOtp(otp);
        if (idToken != null && mounted) {
          final success = await ref.read(authProvider.notifier).firebasePhoneLogin(
            idToken,
            _phoneController.text.trim(),
          );
          if (success && mounted) context.go('/');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String msg = 'OTP မှားနေပါတယ်';
          if (e.code == 'invalid-verification-code') msg = 'OTP code မှားနေပါတယ်';
          if (e.code == 'session-expired') msg = 'OTP သက်တမ်းကုန်ပါပြီ။ OTP အသစ်တောင်းပါ';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    } else {
      // Fallback: backend verify
      final success = await ref.read(authProvider.notifier).verifyOtp(
        _phoneController.text.trim(), otp,
      );
      if (success && mounted) context.go('/');
    }

    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _signInWithFirebaseCredential(PhoneAuthCredential credential) async {
    try {
      final idToken = await _firebaseAuth.signInWithCredential(credential);
      if (idToken != null && mounted) {
        final success = await ref.read(authProvider.notifier).firebasePhoneLogin(
          idToken,
          _phoneController.text.trim(),
        );
        if (success && mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _isSendingOtp || _isVerifying || authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Employee Login', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Enter your registered phone number',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightTextSecondary)),
              const SizedBox(height: 40),

              // Phone Number
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  hintText: '09xxxxxxxxx',
                  prefixIcon: Icon(Iconsax.call, size: 20),
                ),
              ),

              if (!_otpSent) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendOtp,
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP'),
                  ),
                ),
              ],

              if (_otpSent) ...[
                const SizedBox(height: 24),

                // Status message
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.present.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.tick_circle, color: AppColors.present, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_statusMessage!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                      ],
                    ),
                  ),

                // Dev OTP Display (only for fallback mode)
                if (!_useFirebase && _devOtp != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.warning_2, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Text('Dev OTP: $_devOtp', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter 6-digit OTP',
                    prefixIcon: Icon(Iconsax.shield_tick, size: 20),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _verifyOtp,
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify & Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _statusMessage = null;
                      _devOtp = null;
                    }),
                    child: const Text('Change phone number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}