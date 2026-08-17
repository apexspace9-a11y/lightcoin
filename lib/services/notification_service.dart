import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _dailyId = 5001;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.name));
    } catch (_) {
      // tz.local safely falls back when a device timezone cannot be resolved.
    }

    const android = AndroidInitializationSettings('app_icon');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    final allowed = await requestPermission();
    if (!allowed) return;

    await _plugin.cancel(id: _dailyId);
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_saving',
        'Nhắc tiết kiệm',
        channelDescription: 'Nhắc ghi chép và kiểm tra kế hoạch chi tiêu mỗi ngày',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'app_icon',
      ),
    );

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Một phút cho ví tiền',
      body: 'Ghi lại chi tiêu hôm nay và xem bạn còn bao nhiêu để chi an toàn.',
      scheduledDate: next,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() => _plugin.cancel(id: _dailyId);

  Future<void> showBudgetAlert({required String title, required String body}) async {
    final allowed = await requestPermission();
    if (!allowed) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Cảnh báo ngân sách',
        channelDescription: 'Cảnh báo khi chi tiêu tiến gần hoặc vượt ngân sách',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'app_icon',
      ),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
