import 'dart:ui' show Color;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationTestResult { sent, permissionDenied, failed }

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _channelId = 'lightcoin_reminders';
  static const _channelName = 'Nhắc hẹn Light Coin';
  static const _system = MethodChannel('lightcoin/system');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Hệ thống vẫn có thể gửi notification với timezone mặc định.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> _appNotificationsEnabled() async {
    try {
      await init();
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() => isReminderChannelEnabled();

  Future<bool> isReminderChannelEnabled() async {
    try {
      await init();
      if (!await _appNotificationsEnabled()) return false;

      final android = _android;
      if (android == null) return true;
      final channels = await android.getNotificationChannels();
      if (channels == null) return true;

      for (final channel in channels) {
        if (channel.id == _channelId) {
          return channel.importance != Importance.none;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions({bool exactAlarm = false}) async {
    try {
      await init();
      final android = _android;
      if (android == null) return true;

      var enabled = await android.areNotificationsEnabled() ?? true;
      if (!enabled) {
        enabled = await android.requestNotificationsPermission() ?? false;
      }
      if (!enabled) return false;

      if (!exactAlarm) return true;
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSystemSettings() async {
    try {
      return await _system.invokeMethod<bool>('openNotificationSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
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
          visibility: NotificationVisibility.public,
        ),
      );

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    bool requestPermission = false,
  }) async {
    if (!at.isAfter(DateTime.now())) return false;

    try {
      await init();
      final enabled = requestPermission
          ? await requestPermissions()
          : await areNotificationsEnabled();
      if (!enabled || !await isReminderChannelEnabled()) return false;

      var exact = false;
      if (requestPermission) {
        try {
          exact = await _android?.requestExactAlarmsPermission() ?? false;
        } catch (_) {
          exact = false;
        }
      }

      final scheduled = tz.TZDateTime.from(at, tz.local);
      final details = _details(body);

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'lightcoin:$id',
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'lightcoin:$id',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancel(int id) async {
    try {
      await init();
      await _plugin.cancel(id: id);
    } catch (_) {
      // Xóa dữ liệu trong app không được thất bại chỉ vì notification service lỗi.
    }
  }

  Future<NotificationTestResult> test() async {
    try {
      await init();
      final allowed = await requestPermissions();
      if (!allowed || !await isReminderChannelEnabled()) {
        return NotificationTestResult.permissionDenied;
      }

      const body = 'Thông báo thử đã hoạt động bình thường.';
      await _plugin.show(
        id: 991001,
        title: 'Light Coin',
        body: body,
        notificationDetails: _details(body),
        payload: 'lightcoin:test',
      );

      return await isReminderChannelEnabled()
          ? NotificationTestResult.sent
          : NotificationTestResult.permissionDenied;
    } catch (_) {
      return NotificationTestResult.failed;
    }
  }
}
