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

  double get totalSaved =>
      goals.fold<double>(0, (sum, goal) => sum + goal.current);
  double get totalTarget =>
      goals.fold<double>(0, (sum, goal) => sum + goal.target);
  double get totalRemaining => goals.fold<double>(
        0,
        (sum, goal) => sum + (goal.target - goal.current).clamp(0, double.infinity),
      );

  int get activeReminderCount {
    final now = DateTime.now();
    return reminders
        .where(
          (item) =>
              item.enabled && !item.done && item.dateTime.isAfter(now),
        )
        .length;
  }

  int get todayCount {
    final now = DateTime.now();
    bool sameDay(DateTime value) =>
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    return events.where((item) => sameDay(item.dateTime)).length +
        reminders.where((item) => !item.done && sameDay(item.dateTime)).length;
  }

  Future<SharedPreferences> _storage() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final prefs = await _storage();

    darkMode = prefs.getBool(_kDark) ?? false;
    notifications = prefs.getBool(_kNotifications) ?? true;

    events
      ..clear()
      ..addAll(_decode(prefs.getString(_kEvents), CalendarItem.fromJson));
    goals
      ..clear()
      ..addAll(_decode(prefs.getString(_kGoals), SavingGoal.fromJson));
    reminders
      ..clear()
      ..addAll(_decode(prefs.getString(_kReminders), ReminderItem.fromJson));

    _sortAll();
    await _cleanUntouchedLegacySeed(prefs);

    loaded = true;
    notifyListeners();

    if (notifications) {
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 250),
          _reconcileAndRestoreNotifications,
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

  void _sortAll() {
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    goals.sort((a, b) => a.deadline.compareTo(b.deadline));
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _cleanUntouchedLegacySeed(SharedPreferences prefs) async {
    if (prefs.getBool(_kLegacySeedCleaned) == true) return;

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

    await prefs.setBool(_kLegacySeedCleaned, true);
  }

  int nextId() =>
      DateTime.now().microsecondsSinceEpoch.remainder(2147000000);

  Future<bool> addEvent(CalendarItem item) async {
    events.add(item);
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _save();
    return _scheduleEvent(item, requestPermission: true);
  }

  Future<bool> updateEvent(CalendarItem item) async {
    final index = events.indexWhere((event) => event.id == item.id);
    if (index < 0) return false;

    events[index] = item;
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _save();
    await NotificationService.instance.cancel(item.id);
    return _scheduleEvent(item, requestPermission: item.remind);
  }

  Future<bool> _scheduleEvent(
    CalendarItem item, {
    required bool requestPermission,
  }) async {
    if (!item.remind || !item.dateTime.isAfter(DateTime.now())) return true;
    if (!notifications) return false;

    return NotificationService.instance.schedule(
      id: item.id,
      title: item.title,
      body: item.note.isEmpty ? 'Bạn có lịch hẹn sắp tới.' : item.note,
      at: item.dateTime,
      requestPermission: requestPermission,
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

  Future<bool> updateGoal(SavingGoal goal) async {
    final index = goals.indexWhere((item) => item.id == goal.id);
    if (index < 0) return false;
    goals[index] = goal;
    goals.sort((a, b) => a.deadline.compareTo(b.deadline));
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> addMoney(int id, double amount) async {
    final index = goals.indexWhere((goal) => goal.id == id);
    if (index < 0 || amount <= 0) return;

    goals[index] = goals[index].copyWith(
      current: goals[index].current + amount,
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
    return _scheduleReminder(reminder, requestPermission: true);
  }

  Future<bool> updateReminder(ReminderItem reminder) async {
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index < 0) return false;

    reminders[index] = reminder;
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _save();
    await NotificationService.instance.cancel(reminder.id);
    return _scheduleReminder(
      reminder,
      requestPermission: reminder.enabled && !reminder.done,
    );
  }

  Future<bool> _scheduleReminder(
    ReminderItem reminder, {
    required bool requestPermission,
  }) async {
    if (!reminder.enabled || reminder.done) return true;
    if (!reminder.dateTime.isAfter(DateTime.now())) return false;
    if (!notifications) return false;

    return NotificationService.instance.schedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.note.isEmpty
          ? 'Đến giờ cho việc bạn đã lên lịch.'
          : reminder.note,
      at: reminder.dateTime,
      requestPermission: requestPermission,
    );
  }

  Future<bool> toggleReminder(
    ReminderItem reminder, {
    bool? done,
    bool? enabled,
  }) async {
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index < 0) return false;

    if (enabled == true && !reminder.dateTime.isAfter(DateTime.now())) {
      return false;
    }

    final updated = reminder.copyWith(done: done, enabled: enabled);
    reminders[index] = updated;
    notifyListeners();
    await _save();

    if (!updated.enabled || updated.done) {
      await NotificationService.instance.cancel(updated.id);
      return true;
    }

    return _scheduleReminder(updated, requestPermission: true);
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
    final prefs = await _storage();
    await prefs.setBool(_kDark, value);
  }

  Future<bool> setNotifications(bool value) async {
    final prefs = await _storage();

    if (value) {
      final permission = await NotificationService.instance.requestPermissions();
      final usable = permission &&
          await NotificationService.instance.isReminderChannelEnabled();
      notifications = usable;
      await prefs.setBool(_kNotifications, usable);
      notifyListeners();

      if (usable) unawaited(_rescheduleAllSafe());
      return usable;
    }

    notifications = false;
    await prefs.setBool(_kNotifications, false);
    notifyListeners();

    for (final event in events) {
      await NotificationService.instance.cancel(event.id);
    }
    for (final reminder in reminders) {
      await NotificationService.instance.cancel(reminder.id);
    }
    return true;
  }

  Future<void> _reconcileAndRestoreNotifications() async {
    try {
      final usable =
          await NotificationService.instance.isReminderChannelEnabled();
      if (!usable && notifications) {
        notifications = false;
        final prefs = await _storage();
        await prefs.setBool(_kNotifications, false);
        notifyListeners();
        return;
      }
      await _rescheduleAll();
    } catch (_) {
      // Dịch vụ phụ không được phép ảnh hưởng đến dữ liệu chính của app.
    }
  }

  Future<void> _rescheduleAllSafe() async {
    try {
      await _rescheduleAll();
    } catch (_) {
      // Khôi phục notification thất bại không được làm hỏng app.
    }
  }

  Future<void> _rescheduleAll() async {
    if (!notifications) return;
    if (!await NotificationService.instance.isReminderChannelEnabled()) return;

    final now = DateTime.now();

    for (final event in events.where(
      (item) => item.remind && item.dateTime.isAfter(now),
    )) {
      await _scheduleEvent(event, requestPermission: false);
    }

    for (final reminder in reminders.where(
      (item) => item.enabled && !item.done && item.dateTime.isAfter(now),
    )) {
      await _scheduleReminder(reminder, requestPermission: false);
    }
  }

  Future<void> _save() async {
    final prefs = await _storage();
    await Future.wait([
      prefs.setString(
        _kEvents,
        jsonEncode(events.map((item) => item.toJson()).toList()),
      ),
      prefs.setString(
        _kGoals,
        jsonEncode(goals.map((item) => item.toJson()).toList()),
      ),
      prefs.setString(
        _kReminders,
        jsonEncode(reminders.map((item) => item.toJson()).toList()),
      ),
    ]);
  }
}
