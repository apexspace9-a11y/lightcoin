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
  double dailyTarget = 0;
  bool dailyReminder = false;
  int reminderHour = 20;
  int reminderMinute = 0;
  String? activeChallengeId;
  DateTime? challengeStartedAt;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    currency = _prefs.getString('currency') ?? 'VND';
    theme = _prefs.getString('theme') ?? 'system';
    dailyTarget = _prefs.getDouble('daily_saving_target') ?? 0.0;
    dailyReminder = _prefs.getBool('daily_reminder') ?? false;
    reminderHour = _prefs.getInt('reminder_hour') ?? 20;
    reminderMinute = _prefs.getInt('reminder_minute') ?? 0;
    activeChallengeId = _prefs.getString('active_challenge_id');
    final started = _prefs.getInt('challenge_started_at');
    challengeStartedAt = started == null ? null : DateTime.fromMillisecondsSinceEpoch(started);

    final allRecords = await _db.getTransactions();
    transactions = allRecords.where((item) => item.isSavingRecord).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    goals = await _db.getGoals();
    ready = true;
    notifyListeners();

    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(reminderHour, reminderMinute);
    }
  }

  DateTime get _now => DateTime.now();

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentMonth(DateTime date) =>
      date.year == _now.year && date.month == _now.month;

  List<MoneyTransaction> get deposits =>
      transactions.where((item) => item.isDeposit).toList();

  List<MoneyTransaction> get withdrawals =>
      transactions.where((item) => item.isWithdrawal).toList();

  double get totalSaved => math.max(
        0.0,
        transactions.fold<double>(
          0.0,
          (sum, item) => sum + (item.isDeposit ? item.amount : -item.amount),
        ),
      ).toDouble();

  double get savedToday => transactions
      .where((item) => _sameDay(item.occurredAt, _now))
      .fold<double>(0.0, (sum, item) => sum + (item.isDeposit ? item.amount : -item.amount));

  double get savedThisMonth => transactions
      .where((item) => _isCurrentMonth(item.occurredAt))
      .fold<double>(0.0, (sum, item) => sum + (item.isDeposit ? item.amount : -item.amount));

  double get freeSaved => math.max(
        0.0,
        transactions.where((item) => item.category == 'free').fold<double>(
              0.0,
              (sum, item) => sum + (item.isDeposit ? item.amount : -item.amount),
            ),
      ).toDouble();

  double get totalGoalTarget =>
      goals.fold<double>(0.0, (sum, goal) => sum + goal.target);

  double get goalSavedTotal =>
      goals.fold<double>(0.0, (sum, goal) => sum + goal.saved);

  double get unassignedSaved => math.max(0.0, totalSaved - goalSavedTotal).toDouble();

  double get overallGoalProgress => totalGoalTarget <= 0
      ? 0.0
      : (goalSavedTotal / totalGoalTarget).clamp(0.0, 1.0).toDouble();

  double dailyNeededForGoal(SavingGoal goal) {
    if (goal.completed) return 0;
    final end = goal.deadline == null ? _day(_now.add(const Duration(days: 90))) : _day(goal.deadline!);
    final days = math.max(1, end.difference(_day(_now)).inDays + 1);
    return goal.remaining / days;
  }

  double get suggestedDailySaving {
    if (goals.isEmpty) return 0;
    return goals.fold<double>(0.0, (sum, goal) => sum + dailyNeededForGoal(goal));
  }

  double get effectiveDailyTarget => dailyTarget > 0 ? dailyTarget : suggestedDailySaving;

  double get todayProgress => effectiveDailyTarget <= 0
      ? 0.0
      : (math.max(0.0, savedToday) / effectiveDailyTarget).clamp(0.0, 1.0).toDouble();

  Set<DateTime> get _savingDays {
    final unique = <String, DateTime>{};
    for (final item in deposits) {
      final day = _day(item.occurredAt);
      unique['${day.year}-${day.month}-${day.day}'] = day;
    }
    return unique.values.toSet();
  }

  int get currentStreak {
    final days = _savingDays;
    if (days.isEmpty) return 0;
    var cursor = _day(_now);
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestStreak {
    final days = _savingDays.toList()..sort();
    if (days.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run += 1;
      } else {
        run = 1;
      }
      best = math.max(best, run);
    }
    return best;
  }

  int get savedDaysThisMonth => _savingDays.where(_isCurrentMonth).length;

  int get depositCount => deposits.length;

  List<double> get last7DaySavings => List<double>.generate(7, (index) {
        final day = _day(_now.subtract(Duration(days: 6 - index)));
        return deposits
            .where((item) => _sameDay(item.occurredAt, day))
            .fold<double>(0.0, (sum, item) => sum + item.amount);
      });

  List<String> get last7DayLabels => List<String>.generate(7, (index) {
        final day = _now.subtract(Duration(days: 6 - index));
        const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
        return names[day.weekday - 1];
      });

  SavingsChallengeDefinition? get activeChallenge {
    final id = activeChallengeId;
    if (id == null) return null;
    for (final item in savingsChallenges) {
      if (item.id == id) return item;
    }
    return null;
  }

  int get challengeProgress {
    final challenge = activeChallenge;
    final started = challengeStartedAt;
    if (challenge == null || started == null) return 0;
    final eligible = deposits.where((item) => !item.occurredAt.isBefore(_day(started))).toList();
    if (challenge.metric == 'entries') return eligible.length;
    final days = <String>{};
    for (final item in eligible) {
      final day = item.occurredAt;
      days.add('${day.year}-${day.month}-${day.day}');
    }
    return days.length;
  }

  bool get challengeCompleted {
    final challenge = activeChallenge;
    return challenge != null && challengeProgress >= challenge.target;
  }

  SavingGoal? goalById(int? id) {
    if (id == null) return null;
    for (final goal in goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  String _categoryForGoal(SavingGoal? goal) =>
      goal == null ? 'free' : 'goal:${goal.id}|${goal.name}';

  Future<void> deposit({
    int? goalId,
    required double amount,
    required String note,
    required DateTime occurredAt,
  }) async {
    if (amount <= 0) return;
    final goal = goalById(goalId);
    if (goalId != null && goal == null) return;

    if (goal != null && goal.id != null) {
      final index = goals.indexWhere((item) => item.id == goal.id);
      final newSaved = goal.saved + amount;
      await _db.updateGoalSaved(goal.id!, newSaved);
      goals[index] = SavingGoal(
        id: goal.id,
        name: goal.name,
        target: goal.target,
        saved: newSaved,
        deadline: goal.deadline,
        createdAt: goal.createdAt,
      );
    }

    final saved = await _db.addTransaction(MoneyTransaction(
      type: 'saving',
      amount: amount,
      category: _categoryForGoal(goal),
      note: note.trim(),
      occurredAt: occurredAt,
    ));
    transactions = [saved, ...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();

    if (goal != null && goal.saved < goal.target && goal.saved + amount >= goal.target) {
      await NotificationService.instance.showSavingsAlert(
        title: 'Hũ đã đầy',
        body: 'Bạn đã hoàn thành mục tiêu “${goal.name}”. Một cột mốc rất đáng giữ nhịp.',
      );
    }
    await _checkChallengeCompletion();
  }

  Future<bool> withdraw({
    int? goalId,
    required double amount,
    required String note,
    required DateTime occurredAt,
  }) async {
    if (amount <= 0) return false;
    final goal = goalById(goalId);
    if (goalId != null && goal == null) return false;
    final available = goal?.saved ?? freeSaved;
    if (amount > available) return false;

    if (goal != null && goal.id != null) {
      final index = goals.indexWhere((item) => item.id == goal.id);
      final newSaved = math.max(0.0, goal.saved - amount).toDouble();
      await _db.updateGoalSaved(goal.id!, newSaved);
      goals[index] = SavingGoal(
        id: goal.id,
        name: goal.name,
        target: goal.target,
        saved: newSaved,
        deadline: goal.deadline,
        createdAt: goal.createdAt,
      );
    }

    final saved = await _db.addTransaction(MoneyTransaction(
      type: 'withdrawal',
      amount: amount,
      category: _categoryForGoal(goal),
      note: note.trim(),
      occurredAt: occurredAt,
    ));
    transactions = [saved, ...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();
    return true;
  }

  Future<void> deleteSavingRecord(int id) async {
    final index = transactions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final record = transactions[index];
    final goal = goalById(record.goalId);
    if (goal != null && goal.id != null) {
      final goalIndex = goals.indexWhere((item) => item.id == goal.id);
      final adjusted = record.isDeposit
          ? math.max(0.0, goal.saved - record.amount).toDouble()
          : goal.saved + record.amount;
      await _db.updateGoalSaved(goal.id!, adjusted);
      goals[goalIndex] = SavingGoal(
        id: goal.id,
        name: goal.name,
        target: goal.target,
        saved: adjusted,
        deadline: goal.deadline,
        createdAt: goal.createdAt,
      );
    }
    await _db.deleteTransaction(id);
    transactions.removeAt(index);
    notifyListeners();
  }

  Future<void> addGoal({
    required String name,
    required double target,
    DateTime? deadline,
  }) async {
    if (name.trim().isEmpty || target <= 0) return;
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

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
    goals = goals.where((goal) => goal.id != id).toList();
    notifyListeners();
  }

  Future<void> startChallenge(String id) async {
    final exists = savingsChallenges.any((item) => item.id == id);
    if (!exists) return;
    activeChallengeId = id;
    challengeStartedAt = _day(DateTime.now());
    await _prefs.setString('active_challenge_id', id);
    await _prefs.setInt('challenge_started_at', challengeStartedAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> stopChallenge() async {
    activeChallengeId = null;
    challengeStartedAt = null;
    await _prefs.remove('active_challenge_id');
    await _prefs.remove('challenge_started_at');
    notifyListeners();
  }

  Future<void> _checkChallengeCompletion() async {
    final challenge = activeChallenge;
    final started = challengeStartedAt;
    if (challenge == null || started == null || !challengeCompleted) return;
    final key = 'challenge_done_${challenge.id}_${started.millisecondsSinceEpoch}';
    if (_prefs.getBool(key) ?? false) return;
    await _prefs.setBool(key, true);
    await NotificationService.instance.showSavingsAlert(
      title: 'Thử thách hoàn thành',
      body: 'Bạn đã hoàn thành “${challenge.title}”. Chuỗi thói quen này đáng được tiếp tục.',
    );
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

  Future<void> setDailyTarget(double value) async {
    dailyTarget = math.max(0.0, value).toDouble();
    await _prefs.setDouble('daily_saving_target', dailyTarget);
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
    dailyTarget = 0;
    activeChallengeId = null;
    challengeStartedAt = null;
    await _prefs.remove('daily_saving_target');
    await _prefs.remove('active_challenge_id');
    await _prefs.remove('challenge_started_at');
    for (final key in _prefs.getKeys().where((key) => key.startsWith('challenge_done_')).toList()) {
      await _prefs.remove(key);
    }
    notifyListeners();
  }
}
