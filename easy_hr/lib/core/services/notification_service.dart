// lib/core/services/notification_service.dart
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EASY HR - NOTIFICATION SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Features:
//  ✅ Local scheduled notifications (15 min before shift)
//  ✅ Background task with workmanager (works when app closed)
//  ✅ Leave status notifications
//  ✅ Payslip ready notifications
//  ✅ Announcement notifications
//  ✅ Channel management (grouped notifications)
//
// Required packages in pubspec.yaml:
//   flutter_local_notifications: ^17.2.4
//   workmanager: ^0.5.2
//   timezone: ^0.9.4
//   shared_preferences: ^2.3.4
//
// Required setup:
//   Android: See NOTIFICATION_SETUP.md
//   iOS: See NOTIFICATION_SETUP.md
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// ==================== CONSTANTS ====================
class NotificationIds {
  static const int checkInReminder = 1001;
  static const int checkOutReminder = 1002;
  static const int leaveStatus = 2001;
  static const int payslipReady = 3001;
  static const int announcement = 4001;
  static const int chatMessage = 5001;
}

class NotificationChannels {
  static const String attendance = 'attendance_channel';
  static const String leave = 'leave_channel';
  static const String payroll = 'payroll_channel';
  static const String announcement = 'announcement_channel';
  static const String chat = 'chat_channel';
}

// ==================== BACKGROUND TASK CALLBACK ====================
// This MUST be a top-level function (outside any class)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'dailyCheckInReminder':
        await _handleDailyReminder(inputData);
        return true;
      case 'checkLeaveStatus':
        await _handleLeaveStatusCheck(inputData);
        return true;
      default:
        return true;
    }
  });
}

Future<void> _handleDailyReminder(Map<String, dynamic>? inputData) async {
  final prefs = await SharedPreferences.getInstance();
  final workStartTime = prefs.getString('work_start_time') ?? '09:00';
  final reminderEnabled = prefs.getBool('checkin_reminder_enabled') ?? true;

  if (!reminderEnabled) return;

  // Parse work start time
  final parts = workStartTime.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  final now = DateTime.now();
  final workStart = DateTime(now.year, now.month, now.day, hour, minute);
  final reminderTime = workStart.subtract(const Duration(minutes: 15));

  // Only show if we're within the reminder window (15 min before to work start)
  if (now.isAfter(reminderTime) && now.isBefore(workStart)) {
    await NotificationService.instance.showInstantNotification(
      id: NotificationIds.checkInReminder,
      title: '⏰ Check-in Reminder',
      body: 'Good morning! ☀️ Your shift starts at $workStartTime. Don\'t forget to check in!',
      channel: NotificationChannels.attendance,
    );
  }
}

Future<void> _handleLeaveStatusCheck(Map<String, dynamic>? inputData) async {
  // This would normally call the API to check for leave status updates
  // For now, it's a placeholder
}

// ==================== NOTIFICATION SERVICE ====================
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ==================== INITIALIZATION ====================
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    await _createChannels();

    // Initialize Workmanager for background tasks
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  // ==================== ANDROID CHANNELS ====================
  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Attendance channel (high importance for reminders)
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.attendance,
      'Attendance Reminders',
      description: 'Check-in/Check-out reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));

    // Leave channel
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.leave,
      'Leave Updates',
      description: 'Leave request status updates',
      importance: Importance.defaultImportance,
    ));

    // Payroll channel
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.payroll,
      'Payroll',
      description: 'Payslip and salary notifications',
      importance: Importance.defaultImportance,
    ));

    // Announcement channel
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.announcement,
      'Announcements',
      description: 'Company announcements',
      importance: Importance.high,
      enableVibration: true,
    ));

    // Chat channel
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.chat,
      'Messages',
      description: 'Chat messages',
      importance: Importance.defaultImportance,
    ));
  }

  // ==================== PERMISSION REQUEST ====================
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true, badge: true, sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // ==================== SCHEDULE DAILY CHECK-IN REMINDER ====================
  /// Schedule a notification 15 minutes before work start time
  /// Call this when user logs in or when company settings change
  Future<void> scheduleCheckInReminder({
    required String workStartTime, // "09:00" format
    int reminderMinutes = 15,
  }) async {
    // Save settings for background task
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_start_time', workStartTime);
    await prefs.setBool('checkin_reminder_enabled', true);

    // Parse time
    final parts = workStartTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Calculate reminder time (15 min before)
    int remHour = hour;
    int remMinute = minute - reminderMinutes;
    if (remMinute < 0) {
      remMinute += 60;
      remHour -= 1;
      if (remHour < 0) remHour += 24;
    }

    // Cancel old reminders
    await _plugin.cancel(NotificationIds.checkInReminder);

    // Schedule daily notification using timezone
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, remHour, remMinute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      NotificationIds.checkInReminder,
      '⏰ Check-in Reminder',
      'Good morning! ☀️ Your shift starts at $workStartTime. Don\'t forget to check in!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.attendance,
          'Attendance Reminders',
          channelDescription: 'Check-in/Check-out reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(
            'Good morning! ☀️ Your shift is about to start. Open the app and check in when you arrive at the office.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Repeats daily!
    );

    debugPrint('✅ Check-in reminder scheduled for $remHour:${remMinute.toString().padLeft(2, '0')} daily');

    // Also register background task as backup (works when app killed)
    await _registerBackgroundTask(workStartTime);
  }

  // ==================== BACKGROUND TASK REGISTRATION ====================
  Future<void> _registerBackgroundTask(String workStartTime) async {
    // Cancel existing tasks
    await Workmanager().cancelByTag('dailyCheckInReminder');

    // Register periodic task (runs approximately every 15 minutes)
    // Workmanager will handle battery optimization
    await Workmanager().registerPeriodicTask(
      'daily-checkin-reminder',
      'dailyCheckInReminder',
      tag: 'dailyCheckInReminder',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      inputData: {'work_start_time': workStartTime},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint('✅ Background task registered for check-in reminder');
  }

  // ==================== CANCEL CHECK-IN REMINDER ====================
  Future<void> cancelCheckInReminder() async {
    await _plugin.cancel(NotificationIds.checkInReminder);
    await Workmanager().cancelByTag('dailyCheckInReminder');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkin_reminder_enabled', false);
    debugPrint('❌ Check-in reminder cancelled');
  }

  // ==================== SCHEDULE CHECK-OUT REMINDER ====================
  Future<void> scheduleCheckOutReminder({
    required String workEndTime, // "17:00" format
    int reminderMinutes = 5,
  }) async {
    final parts = workEndTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    int remHour = hour;
    int remMinute = minute - reminderMinutes;
    if (remMinute < 0) {
      remMinute += 60;
      remHour -= 1;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, remHour, remMinute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      NotificationIds.checkOutReminder,
      '🏠 Check-out Reminder',
      'Your shift ends at $workEndTime. Don\'t forget to check out!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.attendance,
          'Attendance Reminders',
          channelDescription: 'Check-in/Check-out reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ==================== INSTANT NOTIFICATIONS ====================

  /// Show a notification immediately
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _getChannelName(channel),
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Leave request status update
  Future<void> showLeaveNotification({
    required String status, // 'approved' or 'rejected'
    required String leaveType,
    required String dates,
    String? rejectionReason,
  }) async {
    final isApproved = status == 'approved';
    await showInstantNotification(
      id: NotificationIds.leaveStatus + DateTime.now().millisecond,
      title: isApproved ? '✅ Leave Approved' : '❌ Leave Rejected',
      body: isApproved
          ? 'Your $leaveType ($dates) has been approved!'
          : 'Your $leaveType ($dates) was rejected.${rejectionReason != null ? ' Reason: $rejectionReason' : ''}',
      channel: NotificationChannels.leave,
      payload: json.encode({'type': 'leave', 'status': status}),
    );
  }

  /// Payslip ready notification
  Future<void> showPayslipNotification({
    required String month,
    required String netSalary,
  }) async {
    await showInstantNotification(
      id: NotificationIds.payslipReady,
      title: '💰 Payslip Ready',
      body: 'Your $month payslip is ready! Net salary: $netSalary MMK',
      channel: NotificationChannels.payroll,
      payload: json.encode({'type': 'payslip', 'month': month}),
    );
  }

  /// Announcement notification
  Future<void> showAnnouncementNotification({
    required String title,
    required String preview,
    required String priority,
  }) async {
    final icon = priority == 'urgent' ? '🔴' : priority == 'important' ? '🟡' : '📢';
    await showInstantNotification(
      id: NotificationIds.announcement + DateTime.now().millisecond,
      title: '$icon $title',
      body: preview,
      channel: NotificationChannels.announcement,
      payload: json.encode({'type': 'announcement'}),
    );
  }

  /// Chat message notification
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String channelName,
  }) async {
    await showInstantNotification(
      id: NotificationIds.chatMessage + DateTime.now().millisecond,
      title: '$senderName • $channelName',
      body: message,
      channel: NotificationChannels.chat,
      payload: json.encode({'type': 'chat', 'channel': channelName}),
    );
  }

  // ==================== NOTIFICATION TAP HANDLER ====================
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = json.decode(payload);
      final type = data['type'];

      // Navigate based on notification type
      // You should use a global navigator key or callback
      debugPrint('📌 Notification tapped: type=$type, data=$data');

      // Example navigation (implement with your navigation system):
      // if (type == 'leave') navigatorKey.currentState?.pushNamed('/leave');
      // if (type == 'payslip') navigatorKey.currentState?.pushNamed('/payroll');
      // if (type == 'announcement') navigatorKey.currentState?.pushNamed('/announcements');
      // if (type == 'chat') navigatorKey.currentState?.pushNamed('/chat');
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  // ==================== CANCEL ALL ====================
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await Workmanager().cancelAll();
  }

  // ==================== HELPERS ====================
  String _getChannelName(String channelId) {
    switch (channelId) {
      case NotificationChannels.attendance: return 'Attendance Reminders';
      case NotificationChannels.leave: return 'Leave Updates';
      case NotificationChannels.payroll: return 'Payroll';
      case NotificationChannels.announcement: return 'Announcements';
      case NotificationChannels.chat: return 'Messages';
      default: return 'General';
    }
  }

  /// Get pending notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }
}