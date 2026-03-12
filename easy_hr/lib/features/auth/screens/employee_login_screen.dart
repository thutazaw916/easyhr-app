import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  ConsumerState<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLogging = false;
  bool _obscurePin = true;

  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'easyhr_device_id';

  Future<String> _getDeviceId() async {
    // Check if we already have a persisted device ID
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Generate from hardware info + timestamp for uniqueness
    final deviceInfo = DeviceInfoPlugin();
    String id;
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      id = info.id;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      id = info.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
    } else {
      id = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Persist in secure storage (Keychain on iOS, survives reinstall)
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.brand} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.utsname.machine;
    }
    return 'Unknown Device';
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    if (phone.isEmpty || pin.isEmpty || pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone and 6-digit PIN'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLogging = true);

    try {
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      final success = await ref.read(authProvider.notifier).pinLogin(
        phone, pin, deviceId, deviceName,
      );

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        final error = ref.read(authProvider).error ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }

    if (mounted) setState(() => _isLogging = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Text('Enter your phone number and PIN from your admin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 40),

              // Phone Number
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '09xxxxxxxxx',
                  prefixIcon: Icon(Iconsax.call, size: 20),
                  labelText: 'Phone Number',
                ),
              ),
              const SizedBox(height: 16),

              // PIN
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '6-digit PIN',
                  prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                  labelText: 'Login PIN',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Iconsax.eye_slash : Iconsax.eye, size: 20),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLogging ? null : _login,
                  icon: _isLogging
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.login),
                  label: Text(_isLogging ? 'Logging in...' : 'Login'),
                ),
              ),
              const SizedBox(height: 24),

              // Security info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.info : AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isDark ? AppColors.info : AppColors.primary).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.shield_tick, color: isDark ? AppColors.info : AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your account is bound to this device for security. Contact admin if you change phones.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}