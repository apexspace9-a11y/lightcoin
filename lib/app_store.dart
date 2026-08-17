import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'notification_service.dart';

class AppStore extends ChangeNotifier {
  static const _kEvents = 'events_v1';
  static const _kGoals = 'goals_v1';
  static const _kReminders = 'reminders_v1';
  static const _kDark = 'dark_v1';
  static const _kNotifications = 'notifications_v1';
  static const _kLegacySeedCleaned = 'legacy_seed_cleaned_v2';

  final List<CalendarItem> events = [];
  final List<SavingGoal> goals = [];
  final List<ReminderItem> reminders = [];

  SharedPreferences? _prefs;
  bool darkMode = false;
  bool notifications = true;
  bool loaded = false;

  double get totalSaved => goals.fold<double>(0, (sum, goal) => sum + goal.current);
  double get totalTarget => goals.fold<double>(0, (sum, goal) => sum + goal.target);
  int get activeReminderCount =>
      reminders.where((item) => item.enabled && !item.done).length;
  int get todayCount {
    final now = DateTime.now();
    bool sameDay(DateTime value) =>
        value.year == now.year && value.month == now.month && value.day == now.day;
    return events.where((item) => sameDay(item.dateTime)).length +
        reminders.where((item) => !item.done && sameDay(item.dateTime)).length;
  }

  Future<SharedPreferences> _storage() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final p = await _storage();

    darkMode = p.getBool(_kDark) ?? false;
    notifications = p.getBool(_kNotifications) ?? true;

    events
      ..clear()
      ..addAll(_decode(p.getString(_kEvents), CalendarItem.fromJson));
    goals
      ..clear()
      ..addAll(_decode(p.getString(_kGoals), SavingGoal.fromJson));
    reminders
      ..clear()
      ..addAll(_decode(p.getString(_kReminders), ReminderItem.fromJson));

    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    goals.sort((a, b) => a.deadline.compareTo(b.deadline));
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    await _cleanUntouchedLegacySeed(p);

    loaded = true;
    notifyListeners();

    if (notifications) {
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 300),
          _rescheduleAllSafe,
        ),
      );
    }
  }

  List<T> _decode<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cleanUntouchedLegacySeed(SharedPreferences p) async {
    if (p.getBool(_kLegacySeedCleaned) == true) return;

    final hasEvent = events.any(
      (item) => item.id == 10001 && item.title == 'Lập kế hoạch tuần',
    );
    final hasGoal = goals.any(
      (item) =>
          item.id == 20001 &&
          item.name == 'Quỹ dự phòng' &&
          item.target == 30000000 &&
          item.current == 6500000,
    );
    final hasReminder = reminders.any(
      (item) =>
          item.id == 30001 && item.title == 'Kiểm tra mục tiêu tiết kiệm',
    );

    if (hasEvent && hasGoal && hasReminder) {
      events.removeWhere((item) => item.id == 10001);
      goals.removeWhere((item) => item.id == 20001);
      reminders.removeWhere((item) => item.id == 30001);
      await _save();
    }

    await p.setBool(_kLegacySeedCleaned, true);
  }

  int nextId() =>
      DateTime.now().microsecondsSinceEpoch.remainder(2147000000);

  Future<bool> addEvent(CalendarItem item) async {
    events.add(item);
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _save();

    if (!item.remind) return true;
    if (!notifications) return false;

    return NotificationService.instance.schedule(
      id: item.id,
      title: item.title,
      body: item.note.isEmpty ? 'Bạn có lịch hẹn sắp tới.' : item.note,
      at: item.dateTime,
      requestPermission: true,
    );
  }

  Future<void> deleteEvent(CalendarItem item) async {
    events.removeWhere((event) => event.id == item.id);
    notifyListeners();
    await _save();
    await NotificationService.instance.cancel(item.id);
  }

  Future<void> addGoal(SavingGoal goal) async {
    goals.add(goal);
    goals.sort((a, b) => a.deadline.compareTo(b.deadline));
    notifyListeners();
    await _save();
  }

  Future<void> addMoney(int id, double amount) async {
    final index = goals.indexWhere((goal) => goal.id == id);
    if (index < 0) return;

    goals[index] = goals[index].copyWith(
      current: (goals[index].current + amount)
          .clamp(0.0, double.infinity)
          .toDouble(),
    );
    notifyListeners();
    await _save();
  }

  Future<void> deleteGoal(int id) async {
    goals.removeWhere((goal) => goal.id == id);
    notifyListeners();
    await _save();
  }

  Future<bool> addReminder(ReminderItem reminder) async {
    reminders.add(reminder);
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _save();

    if (!reminder.enabled) return true;
    if (!notifications) return false;

    return NotificationService.instance.schedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.note.isEmpty
          ? 'Đến giờ cho việc bạn đã lên lịch.'
          : reminder.note,
      at: reminder.dateTime,
      requestPermission: true,
    );
  }

  Future<bool> toggleReminder(
    ReminderItem reminder, {
    bool? done,
    bool? enabled,
  }) async {
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index < 0) return false;

    final updated = reminder.copyWith(done: done, enabled: enabled);
    reminders[index] = updated;
    notifyListeners();
    await _save();

    if (!updated.enabled || updated.done) {
      await NotificationService.instance.cancel(updated.id);
      return true;
    }

    if (!notifications) return false;
    return NotificationService.instance.schedule(
      id: updated.id,
      title: updated.title,
      body: updated.note.isEmpty
          ? 'Đến giờ cho việc bạn đã lên lịch.'
          : updated.note,
      at: updated.dateTime,
      requestPermission: true,
    );
  }

  Future<void> deleteReminder(int id) async {
    reminders.removeWhere((reminder) => reminder.id == id);
    notifyListeners();
    await _save();
    await NotificationService.instance.cancel(id);
  }

  Future<void> setDark(bool value) async {
    darkMode = value;
    notifyListeners();
    final p = await _storage();
    await p.setBool(_kDark, value);
  }

  Future<bool> setNotifications(bool value) async {
    final p = await _storage();

    if (value) {
      final allowed = await NotificationService.instance.requestPermissions();
      notifications = allowed;
      await p.setBool(_kNotifications, allowed);
      notifyListeners();

      if (allowed) unawaited(_rescheduleAllSafe());
      return allowed;
    }

    notifications = false;
    await p.setBool(_kNotifications, false);
    notifyListeners();

    for (final event in events) {
      await NotificationService.instance.cancel(event.id);
    }
    for (final reminder in reminders) {
      await NotificationService.instance.cancel(reminder.id);
    }
    return true;
  }

  Future<void> _rescheduleAllSafe() async {
    try {
      await _rescheduleAll();
    } catch (_) {
      // Khôi phục nhắc hẹn không được phép làm chậm hoặc làm hỏng app.
    }
  }

  Future<void> _rescheduleAll() async {
    if (!notifications) return;
    if (!await NotificationService.instance.areNotificationsEnabled()) return;

    final now = DateTime.now();

    for (final event in events.where(
      (item) => item.remind && item.dateTime.isAfter(now),
    )) {
      await NotificationService.instance.schedule(
        id: event.id,
        title: event.title,
        body: event.note.isEmpty ? 'Bạn có lịch hẹn sắp tới.' : event.note,
        at: event.dateTime,
      );
    }

    for (final reminder in reminders.where(
      (item) => item.enabled && !item.done && item.dateTime.isAfter(now),
    )) {
      await NotificationService.instance.schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.note.isEmpty
            ? 'Đến giờ cho việc bạn đã lên lịch.'
            : reminder.note,
        at: reminder.dateTime,
      );
    }
  }

  Future<void> _save() async {
    final p = await _storage();
    await Future.wait([
      p.setString(
        _kEvents,
        jsonEncode(events.map((item) => item.toJson()).toList()),
      ),
      p.setString(
        _kGoals,
        jsonEncode(goals.map((item) => item.toJson()).toList()),
      ),
      p.setString(
        _kReminders,
        jsonEncode(reminders.map((item) => item.toJson()).toList()),
      ),
    ]);
  }
}
