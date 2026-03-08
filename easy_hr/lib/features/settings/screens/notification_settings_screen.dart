// lib/features/settings/screens/notification_settings_screen.dart
//
// UI for managing notification preferences
// Toggle check-in/out reminders, leave updates, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _checkInReminder = true;
  bool _checkOutReminder = true;
  bool _leaveUpdates = true;
  bool _payslipNotif = true;
  bool _announcementNotif = true;
  bool _chatNotif = true;
  String _workStartTime = '09:00';
  String _workEndTime = '17:00';
  int _reminderMinutes = 15;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _checkInReminder = prefs.getBool('checkin_reminder_enabled') ?? true;
        _checkOutReminder = prefs.getBool('checkout_reminder_enabled') ?? true;
        _leaveUpdates = prefs.getBool('leave_notif_enabled') ?? true;
        _payslipNotif = prefs.getBool('payslip_notif_enabled') ?? true;
        _announcementNotif = prefs.getBool('announcement_notif_enabled') ?? true;
        _chatNotif = prefs.getBool('chat_notif_enabled') ?? true;
        _workStartTime = prefs.getString('work_start_time') ?? '09:00';
        _workEndTime = prefs.getString('work_end_time') ?? '17:00';
        _reminderMinutes = prefs.getInt('reminder_minutes') ?? 15;
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkin_reminder_enabled', _checkInReminder);
    await prefs.setBool('checkout_reminder_enabled', _checkOutReminder);
    await prefs.setBool('leave_notif_enabled', _leaveUpdates);
    await prefs.setBool('payslip_notif_enabled', _payslipNotif);
    await prefs.setBool('announcement_notif_enabled', _announcementNotif);
    await prefs.setBool('chat_notif_enabled', _chatNotif);
    await prefs.setString('work_start_time', _workStartTime);
    await prefs.setString('work_end_time', _workEndTime);
    await prefs.setInt('reminder_minutes', _reminderMinutes);

    // Update scheduled notifications
    final ns = NotificationService.instance;
    if (_checkInReminder) {
      await ns.scheduleCheckInReminder(
        workStartTime: _workStartTime,
        reminderMinutes: _reminderMinutes,
      );
    } else {
      await ns.cancelCheckInReminder();
    }

    if (_checkOutReminder) {
      await ns.scheduleCheckOutReminder(workEndTime: _workEndTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        title: Text(mm ? 'အကြောင်းကြားချက် ဆက်တင်' : 'Notification Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== ATTENDANCE REMINDERS =====
                  _sectionHeader(isDark, mm,
                    icon: Iconsax.clock,
                    title: mm ? 'တက်ရောက်မှု သတိပေးချက်' : 'Attendance Reminders',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 8),

                  _toggleCard(isDark, mm,
                    icon: Iconsax.login,
                    title: mm ? 'Check-In သတိပေး' : 'Check-In Reminder',
                    subtitle: mm
                        ? 'အလုပ်စချိန် $_reminderMinutes မိနစ်အလို'
                        : '$_reminderMinutes min before shift',
                    value: _checkInReminder,
                    onChanged: (v) {
                      setState(() => _checkInReminder = v);
                      _saveSettings();
                    },
                    trailing: _checkInReminder ? GestureDetector(
                      onTap: () => _showTimePicker(mm, isStart: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_workStartTime,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                      ),
                    ) : null,
                  ),

                  if (_checkInReminder) ...[
                    const SizedBox(height: 8),
                    _reminderMinuteSelector(isDark, mm),
                  ],

                  const SizedBox(height: 8),
                  _toggleCard(isDark, mm,
                    icon: Iconsax.logout,
                    title: mm ? 'Check-Out သတိပေး' : 'Check-Out Reminder',
                    subtitle: mm ? 'အလုပ်ဆင်းချိန် ၅ မိနစ်အလို' : '5 min before shift ends',
                    value: _checkOutReminder,
                    onChanged: (v) {
                      setState(() => _checkOutReminder = v);
                      _saveSettings();
                    },
                    trailing: _checkOutReminder ? GestureDetector(
                      onTap: () => _showTimePicker(mm, isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_workEndTime,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 14)),
                      ),
                    ) : null,
                  ),

                  const SizedBox(height: 24),

                  // ===== LEAVE & PAYROLL =====
                  _sectionHeader(isDark, mm,
                    icon: Iconsax.calendar_tick,
                    title: mm ? 'ခွင့်နှင့် လစာ' : 'Leave & Payroll',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),

                  _toggleCard(isDark, mm,
                    icon: Iconsax.calendar_tick,
                    title: mm ? 'ခွင့်အခြေအနေ' : 'Leave Status Updates',
                    subtitle: mm ? 'ခွင့်ခွင့်ပြု/ပယ်ချ အကြောင်းကြား' : 'Approved/Rejected notifications',
                    value: _leaveUpdates,
                    onChanged: (v) { setState(() => _leaveUpdates = v); _saveSettings(); },
                  ),
                  const SizedBox(height: 8),
                  _toggleCard(isDark, mm,
                    icon: Iconsax.money_recive,
                    title: mm ? 'လစာ Payslip' : 'Payslip Notifications',
                    subtitle: mm ? 'လစာ ထုတ်ပြီးအကြောင်းကြား' : 'When payslip is ready',
                    value: _payslipNotif,
                    onChanged: (v) { setState(() => _payslipNotif = v); _saveSettings(); },
                  ),

                  const SizedBox(height: 24),

                  // ===== COMMUNICATION =====
                  _sectionHeader(isDark, mm,
                    icon: Iconsax.message,
                    title: mm ? 'ဆက်သွယ်ရေး' : 'Communication',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 8),

                  _toggleCard(isDark, mm,
                    icon: Iconsax.notification,
                    title: mm ? 'ကြေငြာချက်များ' : 'Announcements',
                    subtitle: mm ? 'ကုမ္ပဏီ ကြေငြာချက်' : 'Company announcements',
                    value: _announcementNotif,
                    onChanged: (v) { setState(() => _announcementNotif = v); _saveSettings(); },
                  ),
                  const SizedBox(height: 8),
                  _toggleCard(isDark, mm,
                    icon: Iconsax.message_text,
                    title: mm ? 'Chat မက်ဆေ့ဂျ်' : 'Chat Messages',
                    subtitle: mm ? 'ဌာန/ကုမ္ပဏီ chat' : 'Department/Company chat',
                    value: _chatNotif,
                    onChanged: (v) { setState(() => _chatNotif = v); _saveSettings(); },
                  ),

                  const SizedBox(height: 30),

                  // ===== TEST BUTTON =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Iconsax.notification_bing, size: 18),
                      label: Text(mm ? 'Test Notification ပို့ကြည့်ရန်' : 'Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await NotificationService.instance.showInstantNotification(
                          id: 9999,
                          title: '🔔 Test Notification',
                          body: mm ? 'Notification အလုပ်လုပ်ပါတယ်! ✅' : 'Notifications are working! ✅',
                          channel: NotificationChannels.attendance,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(mm ? '✅ Test notification ပို့ပြီး!' : '✅ Test notification sent!'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _sectionHeader(bool isDark, bool mm, {
    required IconData icon, required String title, required Color color,
  }) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
          color: isDark ? Colors.white : Colors.black)),
    ]);
  }

  Widget _toggleCard(bool isDark, bool mm, {
    required IconData icon, required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged, Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: value ? AppColors.primary : AppColors.lightTextSecondary),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                color: isDark ? Colors.white : Colors.black)),
            Text(subtitle, style: TextStyle(fontSize: 11,
                color: isDark ? Colors.white : Colors.black)),
          ],
        )),
        if (trailing != null) ...[trailing, const SizedBox(width: 8)],
        Switch.adaptive(
          value: value, onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ]),
    );
  }

  Widget _reminderMinuteSelector(bool isDark, bool mm) {
    final options = [5, 10, 15, 30];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mm ? 'ကြိုတင်သတိပေးချိန်' : 'Reminder Time Before Shift',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 8),
          Row(
            children: options.map((m) {
              final active = _reminderMinutes == m;
              return Expanded(child: GestureDetector(
                onTap: () {
                  setState(() => _reminderMinutes = m);
                  _saveSettings();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: active ? AppColors.primary : Colors.grey.shade400),
                  ),
                  child: Text('${m}m', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.grey)),
                ),
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(bool mm, {required bool isStart}) async {
    final currentTime = isStart ? _workStartTime : _workEndTime;
    final parts = currentTime.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (time != null) {
      final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) _workStartTime = formatted;
        else _workEndTime = formatted;
      });
      _saveSettings();
    }
  }
}