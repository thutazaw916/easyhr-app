import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class QRAttendanceScanScreen extends ConsumerStatefulWidget {
  const QRAttendanceScanScreen({super.key});

  @override
  ConsumerState<QRAttendanceScanScreen> createState() => _QRAttendanceScanScreenState();
}

class _QRAttendanceScanScreenState extends ConsumerState<QRAttendanceScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _handling = true;
      _error = null;
    });

    final lang = ref.read(languageProvider);
    final mm = lang == 'mm';

    try {
      final api = ref.read(apiServiceProvider);
      await api.qrCheckIn(raw);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mm ? '✅ QR ဖြင့် Check-in သတ်မှတ်ပြီးပါပြီ' : '✅ QR check-in successful'),
          backgroundColor: AppColors.present,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      String msg;
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final backendMsg = data is Map<String, dynamic> ? data['message']?.toString() : null;

        if (status == 400 && backendMsg != null) {
          msg = backendMsg;
        } else if (status == 403) {
          msg = mm
              ? 'ဤ QR ကို သင့်အတွက် အသုံးမပြုနိုင်ပါ'
              : 'You are not allowed to use this QR code.';
        } else {
          msg = backendMsg ??
              (mm ? 'QR ဖြင့် Check-in မအောင်မြင်ပါ' : 'QR check-in failed. Please try again.');
        }
      } else {
        msg = e.toString();
      }

      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $msg'),
            backgroundColor: AppColors.absent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _handling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final s = AppStrings.get(lang);
    final mm = lang == 'mm';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(s['scan_qr'] ?? (mm ? 'QR ကုဒ်စကန်ဖတ်ရန်' : 'Scan QR Code')),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.flash_1),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Iconsax.camera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.75) : Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['scan_qr'] ?? (mm ? 'QR ကုဒ်စကန်ဖတ်ရန်' : 'Scan QR Code'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mm
                        ? 'ရုံးမှ ဆက်ထားသော Attendance QR ကို စကန်ဖတ်ပါ'
                        : 'Point the camera at your office attendance QR code.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_handling) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.absent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

