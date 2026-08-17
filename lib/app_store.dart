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
  final List<CalendarItem> events = [];
  final List<SavingGoal> goals = [];
  final List<ReminderItem> reminders = [];
  bool darkMode = false;
  bool notifications = true;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    darkMode = p.getBool(_kDark) ?? false;
    notifications = p.getBool(_kNotifications) ?? true;
    events.addAll(_decode(p.getString(_kEvents), CalendarItem.fromJson));
    goals.addAll(_decode(p.getString(_kGoals), SavingGoal.fromJson));
    reminders.addAll(_decode(p.getString(_kReminders), ReminderItem.fromJson));
    if (events.isEmpty && goals.isEmpty && reminders.isEmpty) _seed();
    notifyListeners();
    if (notifications) await _rescheduleAll();
  }

  List<T> _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null || raw.isEmpty) return [];
    try { return (jsonDecode(raw) as List).map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList(); } catch (_) { return []; }
  }

  void _seed() {
    final now = DateTime.now();
    events.add(CalendarItem(id: 10001, title: 'Lập kế hoạch tuần', dateTime: DateTime(now.year, now.month, now.day, 19, 30), note: '15 phút để chọn 3 ưu tiên quan trọng.', category: 'Công việc', remind: false));
    goals.add(SavingGoal(id: 20001, name: 'Quỹ dự phòng', target: 30000000, current: 6500000, deadline: DateTime(now.year + 1, 1, 1)));
    reminders.add(ReminderItem(id: 30001, title: 'Kiểm tra mục tiêu tiết kiệm', dateTime: now.add(const Duration(days: 7)), note: 'Cập nhật số tiền đã tiết kiệm.', enabled: false));
    _save();
  }

  int nextId() => DateTime.now().microsecondsSinceEpoch.remainder(2147000000);
  Future<void> addEvent(CalendarItem item) async { events.add(item); events.sort((a,b)=>a.dateTime.compareTo(b.dateTime)); await _save(); if (notifications && item.remind) await NotificationService.instance.schedule(id: item.id, title: item.title, body: item.note.isEmpty ? 'Bạn có lịch hẹn sắp tới.' : item.note, at: item.dateTime); notifyListeners(); }
  Future<void> deleteEvent(CalendarItem item) async { events.removeWhere((e)=>e.id==item.id); await NotificationService.instance.cancel(item.id); await _save(); notifyListeners(); }
  Future<void> addGoal(SavingGoal goal) async { goals.add(goal); await _save(); notifyListeners(); }
  Future<void> addMoney(int id, double amount) async { final i=goals.indexWhere((g)=>g.id==id); if(i<0)return; goals[i]=goals[i].copyWith(current:(goals[i].current+amount).clamp(0,double.infinity)); await _save(); notifyListeners(); }
  Future<void> deleteGoal(int id) async { goals.removeWhere((g)=>g.id==id); await _save(); notifyListeners(); }
  Future<void> addReminder(ReminderItem r) async { reminders.add(r); reminders.sort((a,b)=>a.dateTime.compareTo(b.dateTime)); await _save(); if(notifications&&r.enabled) await NotificationService.instance.schedule(id:r.id,title:r.title,body:r.note.isEmpty?'Đến giờ cho việc bạn đã lên lịch.':r.note,at:r.dateTime); notifyListeners(); }
  Future<void> toggleReminder(ReminderItem r,{bool? done,bool? enabled}) async { final i=reminders.indexWhere((x)=>x.id==r.id); if(i<0)return; final updated=r.copyWith(done:done,enabled:enabled); reminders[i]=updated; if(updated.enabled&&!updated.done&&notifications) { await NotificationService.instance.schedule(id:updated.id,title:updated.title,body:updated.note.isEmpty?'Đến giờ cho việc bạn đã lên lịch.':updated.note,at:updated.dateTime); } else { await NotificationService.instance.cancel(updated.id); } await _save(); notifyListeners(); }
  Future<void> deleteReminder(int id) async { reminders.removeWhere((r)=>r.id==id); await NotificationService.instance.cancel(id); await _save(); notifyListeners(); }
  Future<void> setDark(bool value) async { darkMode=value; final p=await SharedPreferences.getInstance(); await p.setBool(_kDark,value); notifyListeners(); }
  Future<void> setNotifications(bool value) async { notifications=value; final p=await SharedPreferences.getInstance(); await p.setBool(_kNotifications,value); if(value){await NotificationService.instance.init();await _rescheduleAll();}else{for(final e in events)await NotificationService.instance.cancel(e.id);for(final r in reminders)await NotificationService.instance.cancel(r.id);} notifyListeners(); }
  Future<void> _rescheduleAll() async { for(final e in events.where((x)=>x.remind&&x.dateTime.isAfter(DateTime.now()))) await NotificationService.instance.schedule(id:e.id,title:e.title,body:e.note.isEmpty?'Bạn có lịch hẹn sắp tới.':e.note,at:e.dateTime); for(final r in reminders.where((x)=>x.enabled&&!x.done&&x.dateTime.isAfter(DateTime.now()))) await NotificationService.instance.schedule(id:r.id,title:r.title,body:r.note.isEmpty?'Đến giờ cho việc bạn đã lên lịch.':r.note,at:r.dateTime); }
  Future<void> _save() async { final p=await SharedPreferences.getInstance(); await p.setString(_kEvents,jsonEncode(events.map((e)=>e.toJson()).toList())); await p.setString(_kGoals,jsonEncode(goals.map((e)=>e.toJson()).toList())); await p.setString(_kReminders,jsonEncode(reminders.map((e)=>e.toJson()).toList())); }
}
