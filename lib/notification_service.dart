import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {}
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(settings: settings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    await init();
    if (!at.isAfter(DateTime.now())) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.requestExactAlarmsPermission() ?? false;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'lightcoin_reminders',
        'Nhắc hẹn Light Coin',
        channelDescription: 'Lịch hẹn, công việc và mục tiêu quan trọng',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(body),
        ticker: 'Light Coin',
        icon: 'ic_notification',
        color: const Color(0xFF6D5DFB),
        enableVibration: true,
        playSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'lightcoin:$id',
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  Future<void> test() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'lightcoin_reminders',
        'Nhắc hẹn Light Coin',
        channelDescription: 'Lịch hẹn, công việc và mục tiêu quan trọng',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        styleInformation:
            BigTextStyleInformation('Thông báo của bạn đã sẵn sàng.'),
        icon: 'ic_notification',
        color: Color(0xFF6D5DFB),
        enableVibration: true,
        playSound: true,
      ),
    );
    await _plugin.show(
      id: 991001,
      title: 'Light Coin',
      body: 'Thông báo của bạn đã sẵn sàng ✨',
      notificationDetails: details,
    );
  }
}
