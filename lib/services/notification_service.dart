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
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Keep the package fallback timezone when a device timezone cannot be resolved.
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
        channelDescription: 'Nhắc duy trì thói quen bỏ tiền vào hũ mỗi ngày',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'app_icon',
      ),
    );

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Đến giờ bỏ ống',
      body: 'Một khoản nhỏ hôm nay vẫn đưa bạn gần mục tiêu hơn ngày hôm qua.',
      scheduledDate: next,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() => _plugin.cancel(id: _dailyId);

  Future<void> showSavingsAlert({required String title, required String body}) async {
    final allowed = await requestPermission();
    if (!allowed) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'saving_milestones',
        'Cột mốc tiết kiệm',
        channelDescription: 'Thông báo khi hoàn thành hũ hoặc thử thách tiết kiệm',
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
