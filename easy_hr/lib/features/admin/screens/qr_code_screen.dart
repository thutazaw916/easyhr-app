import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/localization/app_strings.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  String? _togglingId;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getBranches();
      setState(() => _branches = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleQr(Map<String, dynamic> branch) async {
    final enabling = branch['qr_code_enabled'] != true;
    final mm = ref.read(languageProvider) == 'mm';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(enabling
            ? (mm ? 'QR Code ဖွင့်မလား?' : 'Enable QR Code?')
            : (mm ? 'QR Code ပိတ်မလား?' : 'Disable QR Code?')),
        content: Text(enabling
            ? (mm
                ? '"${branch['name']}" အတွက် QR code ဖွင့်ပေးမယ်။ ဝန်ထမ်းတွေ scan ဖတ်ပြီး check in လုပ်နိုင်မယ်။'
                : 'Enable QR code for "${branch['name']}"? Employees can scan to check in.')
            : (mm
                ? '"${branch['name']}" QR code ကို ပိတ်မယ်။ လက်ရှိ QR code သုံးလို့ ရမှာ မဟုတ်တော့ပါ။'
                : 'Disable QR code for "${branch['name']}"? Current code will be invalidated.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(mm ? 'မလုပ်တော့' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enabling ? AppColors.primary : AppColors.absent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(enabling ? (mm ? 'ဖွင့်မယ်' : 'Enable') : (mm ? 'ပိတ်မယ်' : 'Disable')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _togglingId = branch['id']);
    try {
      final api = ref.read(apiServiceProvider);
      await api.toggleBranchQr(branch['id'], enabling);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabling
                ? (mm ? '✅ QR Code ဖွင့်ပြီး!' : '✅ QR Code enabled!')
                : (mm ? 'QR Code ပိတ်ပြီး' : 'QR Code disabled')),
            backgroundColor: enabling ? AppColors.present : AppColors.absent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadBranches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${mm ? 'QR Code ပြောင်းလို့မရပါ' : 'Failed to toggle QR code'}'),
            backgroundColor: AppColors.absent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _togglingId = null);
  }

  Future<void> _shareQr(Map<String, dynamic> branch) async {
    final mm = ref.read(languageProvider) == 'mm';
    final key = GlobalKey();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build QR widget offscreen and capture
      final qrWidget = RepaintBoundary(
        key: key,
        child: Container(
          width: 512,
          height: 620,
          color: const Color(0xFF1C1C1E),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: branch['qr_secret_key'] ?? '',
                  version: QrVersions.auto,
                  size: 280,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                branch['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mm ? 'Scan ဖတ်ပြီး Check In လုပ်ပါ • Easy HR' : 'Scan to Check In • Easy HR',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );

      // Use an overlay to render offscreen
      final overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -1000,
          top: -1000,
          child: qrWidget,
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not capture QR');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      overlayEntry.remove();

      if (byteData == null) throw Exception('Could not generate image');

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/EasyHR-QR-${branch['name']?.toString().replaceAll(' ', '-') ?? 'branch'}.png');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context); // dismiss loading

      await Share.shareXFiles(
        [XFile(file.path)],
        text: mm
            ? '${branch['name']} QR Code - Easy HR မှ Check In အတွက်'
            : '${branch['name']} QR Code - Scan to Check In with Easy HR',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mm ? 'မျှဝေလို့ မရပါ' : 'Failed to share QR code'),
            backgroundColor: AppColors.absent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(mm ? 'QR Code စီမံခန့်ခွဲမှု' : 'QR Code Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? _buildEmpty(mm)
              : RefreshIndicator(
                  onRefresh: _loadBranches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _branches.length + 1, // +1 for info card
                    itemBuilder: (context, index) {
                      if (index < _branches.length) {
                        return _buildBranchQrCard(isDark, mm, _branches[index]);
                      }
                      return _buildInfoCard(isDark, mm);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool mm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.building_4, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            mm ? 'ရုံးခွဲ မရှိသေးပါ' : 'No branches found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            mm ? 'QR code များကို ရုံးခွဲအလိုက် အလိုအလျောက် ထုတ်ပေးပါသည်' : 'QR codes are auto-generated for each branch',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchQrCard(bool isDark, bool mm, Map<String, dynamic> branch) {
    final qrEnabled = branch['qr_code_enabled'] == true;
    final qrKey = branch['qr_secret_key'] as String?;
    final isToggling = _togglingId == branch['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.building, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (branch['address'] != null && branch['address'].toString().isNotEmpty)
                        Text(
                          branch['address'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Toggle button
                GestureDetector(
                  onTap: isToggling ? null : () => _toggleQr(branch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: qrEnabled
                          ? AppColors.absent.withOpacity(0.1)
                          : AppColors.present.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isToggling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                qrEnabled ? Iconsax.close_circle : Iconsax.tick_circle,
                                size: 16,
                                color: qrEnabled ? AppColors.absent : AppColors.present,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                qrEnabled
                                    ? (mm ? 'ပိတ်မယ်' : 'Disable')
                                    : (mm ? 'ဖွင့်မယ်' : 'Enable'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: qrEnabled ? AppColors.absent : AppColors.present,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // QR Code area
          Padding(
            padding: const EdgeInsets.all(20),
            child: qrEnabled && qrKey != null && qrKey.isNotEmpty
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qrKey,
                          version: QrVersions.auto,
                          size: 200,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mm
                            ? 'ဝန်ထမ်းတွေ Easy HR app နဲ့ scan ဖတ်ပြီး check in လုပ်ပါ'
                            : 'Employees scan with Easy HR app to check in',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Iconsax.share, size: 18),
                          label: Text(mm ? 'QR Code မျှဝေမယ်' : 'Share QR Code'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _shareQr(branch),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Iconsax.scan_barcode,
                        size: 64,
                        color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                            .withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mm ? 'QR Code ပိတ်ထားပါသည်' : 'QR Code is disabled',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mm
                            ? 'ဖွင့်ပြီး QR code generate လုပ်ပါ'
                            : 'Enable to generate a QR code for check-in',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, bool mm) {
    final steps = mm
        ? [
            {'step': '1', 'title': 'ဖွင့်ပြီး Share လုပ်ပါ', 'desc': 'QR code ဖွင့်ပြီး ပုံကို save/share လုပ်ပါ'},
            {'step': '2', 'title': 'Print ထုတ်ပြီး ကပ်ပါ', 'desc': 'QR code ကို print ထုတ်ပြီး ရုံးဝင်ပေါက်မှာ ကပ်ပါ'},
            {'step': '3', 'title': 'Scan ဖတ်ပြီး Check In', 'desc': 'ဝန်ထမ်းတွေ app နဲ့ scan ဖတ်ပြီး check in/out လုပ်ပါ'},
          ]
        : [
            {'step': '1', 'title': 'Enable & Share', 'desc': 'Enable QR code and save/share the image'},
            {'step': '2', 'title': 'Print & Display', 'desc': 'Print the QR code and place at office entrance'},
            {'step': '3', 'title': 'Scan to Check In', 'desc': 'Employees scan with Easy HR app to check in/out'},
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.scan_barcode, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                mm ? 'QR Code Attendance အသုံးပြုပုံ' : 'How QR Code Attendance Works',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          s['step']!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            s['desc']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
