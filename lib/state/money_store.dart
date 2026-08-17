import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/money_database.dart';
import '../models.dart';
import '../services/notification_service.dart';

class MoneyStore extends ChangeNotifier {
  final _db = MoneyDatabase.instance;
  late SharedPreferences _prefs;

  List<MoneyTransaction> transactions = [];
  List<SavingGoal> goals = [];
  bool ready = false;

  String currency = 'VND';
  String theme = 'system';
  double monthlyBudget = 0;
  Map<String, double> categoryBudgets = {};
  bool dailyReminder = false;
  int reminderHour = 20;
  int reminderMinute = 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    currency = _prefs.getString('currency') ?? 'VND';
    theme = _prefs.getString('theme') ?? 'system';
    monthlyBudget = _prefs.getDouble('monthly_budget') ?? 0.0;
    dailyReminder = _prefs.getBool('daily_reminder') ?? false;
    reminderHour = _prefs.getInt('reminder_hour') ?? 20;
    reminderMinute = _prefs.getInt('reminder_minute') ?? 0;

    final rawBudgets = _prefs.getString('category_budgets');
    if (rawBudgets != null && rawBudgets.isNotEmpty) {
      final decoded = jsonDecode(rawBudgets) as Map<String, dynamic>;
      categoryBudgets = decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    transactions = await _db.getTransactions();
    goals = await _db.getGoals();
    ready = true;
    notifyListeners();

    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(reminderHour, reminderMinute);
    }
  }

  DateTime get _now => DateTime.now();

  bool _isCurrentMonth(DateTime date) =>
      date.year == _now.year && date.month == _now.month;

  double get balance => transactions.fold<double>(
        0.0,
        (sum, item) => sum + (item.isIncome ? item.amount : -item.amount),
      );

  double get monthIncome => transactions
      .where((t) => t.isIncome && _isCurrentMonth(t.occurredAt))
      .fold<double>(0.0, (sum, item) => sum + item.amount);

  double get monthExpense => transactions
      .where((t) => !t.isIncome && _isCurrentMonth(t.occurredAt))
      .fold<double>(0.0, (sum, item) => sum + item.amount);

  double get savingsRate {
    if (monthIncome <= 0) return 0;
    return (((monthIncome - monthExpense) / monthIncome) * 100).clamp(-999.0, 100.0).toDouble();
  }

  double get budgetProgress =>
      monthlyBudget <= 0 ? 0.0 : (monthExpense / monthlyBudget).clamp(0.0, 2.0).toDouble();

  double get remainingBudget => monthlyBudget <= 0 ? 0 : monthlyBudget - monthExpense;

  double get safeDailySpend {
    if (monthlyBudget <= 0) return 0;
    final lastDay = DateTime(_now.year, _now.month + 1, 0).day;
    final daysLeft = math.max(1, lastDay - _now.day + 1);
    return math.max(0.0, remainingBudget).toDouble() / daysLeft;
  }

  Map<String, double> get currentMonthExpensesByCategory {
    final result = <String, double>{};
    for (final item in transactions.where(
      (t) => !t.isIncome && _isCurrentMonth(t.occurredAt),
    )) {
      result[item.category] = (result[item.category] ?? 0.0) + item.amount;
    }
    return result;
  }

  List<double> get lastSixMonthNet {
    final now = _now;
    return List<double>.generate(6, (index) {
      final offset = 5 - index;
      final date = DateTime(now.year, now.month - offset, 1);
      return transactions.where((t) {
        return t.occurredAt.year == date.year && t.occurredAt.month == date.month;
      }).fold<double>(0.0, (sum, item) => sum + (item.isIncome ? item.amount : -item.amount));
    });
  }

  List<String> get lastSixMonthLabels {
    final now = _now;
    return List<String>.generate(6, (index) {
      final offset = 5 - index;
      final date = DateTime(now.year, now.month - offset, 1);
      return 'T${date.month}';
    });
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String note,
    required DateTime occurredAt,
  }) async {
    final saved = await _db.addTransaction(MoneyTransaction(
      type: type,
      amount: amount,
      category: category,
      note: note.trim(),
      occurredAt: occurredAt,
    ));
    transactions = [saved, ...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();
    if (type == 'expense' && _isCurrentMonth(occurredAt)) {
      await _checkBudgetAlerts(category);
    }
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    transactions = transactions.where((item) => item.id != id).toList();
    notifyListeners();
  }

  Future<void> addGoal({
    required String name,
    required double target,
    DateTime? deadline,
  }) async {
    final saved = await _db.addGoal(SavingGoal(
      name: name.trim(),
      target: target,
      saved: 0,
      deadline: deadline,
      createdAt: DateTime.now(),
    ));
    goals = [saved, ...goals];
    notifyListeners();
  }

  Future<void> addToGoal(int id, double amount) async {
    final index = goals.indexWhere((goal) => goal.id == id);
    if (index < 0) return;
    final goal = goals[index];
    final newSaved = math.max(0.0, goal.saved + amount).toDouble();
    await _db.updateGoalSaved(id, newSaved);
    goals[index] = SavingGoal(
      id: goal.id,
      name: goal.name,
      target: goal.target,
      saved: newSaved,
      deadline: goal.deadline,
      createdAt: goal.createdAt,
    );
    notifyListeners();
    if (newSaved >= goal.target && goal.saved < goal.target) {
      await NotificationService.instance.showBudgetAlert(
        title: 'Mục tiêu đã hoàn thành',
        body: 'Bạn đã hoàn thành mục tiêu “${goal.name}”. Hãy tiếp tục duy trì thói quen tiết kiệm.',
      );
    }
  }

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
    goals = goals.where((goal) => goal.id != id).toList();
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    currency = value;
    await _prefs.setString('currency', value);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await _prefs.setString('theme', value);
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double value) async {
    monthlyBudget = math.max(0.0, value).toDouble();
    await _prefs.setDouble('monthly_budget', monthlyBudget);
    notifyListeners();
  }

  Future<void> setCategoryBudget(String category, double value) async {
    if (value <= 0) {
      categoryBudgets.remove(category);
    } else {
      categoryBudgets[category] = value;
    }
    await _prefs.setString('category_budgets', jsonEncode(categoryBudgets));
    notifyListeners();
  }

  Future<void> setReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    dailyReminder = enabled;
    if (hour != null) reminderHour = hour;
    if (minute != null) reminderMinute = minute;
    await _prefs.setBool('daily_reminder', dailyReminder);
    await _prefs.setInt('reminder_hour', reminderHour);
    await _prefs.setInt('reminder_minute', reminderMinute);
    notifyListeners();
    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(reminderHour, reminderMinute);
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> clearEverything() async {
    await _db.clearAll();
    transactions = [];
    goals = [];
    monthlyBudget = 0;
    categoryBudgets = {};
    await _prefs.remove('monthly_budget');
    await _prefs.remove('category_budgets');
    final keys = _prefs.getKeys().where((key) => key.startsWith('alert_')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    notifyListeners();
  }

  Future<void> _checkBudgetAlerts(String category) async {
    final monthKey = '${_now.year}_${_now.month}';
    if (monthlyBudget > 0) {
      final ratio = monthExpense / monthlyBudget;
      await _alertThreshold(
        keyBase: 'alert_total_$monthKey',
        ratio: ratio,
        label: 'ngân sách tháng',
      );
    }

    final categoryLimit = categoryBudgets[category] ?? 0.0;
    if (categoryLimit > 0) {
      final spent = currentMonthExpensesByCategory[category] ?? 0.0;
      await _alertThreshold(
        keyBase: 'alert_${category}_$monthKey',
        ratio: spent / categoryLimit,
        label: 'ngân sách $category',
      );
    }
  }

  Future<void> _alertThreshold({
    required String keyBase,
    required double ratio,
    required String label,
  }) async {
    if (ratio >= 1) {
      final key = '${keyBase}_100';
      if (!(_prefs.getBool(key) ?? false)) {
        await _prefs.setBool(key, true);
        await NotificationService.instance.showBudgetAlert(
          title: 'Đã vượt $label',
          body: 'Chi tiêu đã chạm ${(ratio * 100).round()}%. Hãy xem lại các khoản chi còn lại trong tháng.',
        );
      }
    } else if (ratio >= .8) {
      final key = '${keyBase}_80';
      if (!(_prefs.getBool(key) ?? false)) {
        await _prefs.setBool(key, true);
        await NotificationService.instance.showBudgetAlert(
          title: 'Sắp chạm $label',
          body: 'Bạn đã dùng ${(ratio * 100).round()}%. Phần còn lại nên được tiêu có chủ đích.',
        );
      }
    }
  }
}
