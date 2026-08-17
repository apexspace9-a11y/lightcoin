class CalendarItem {
  CalendarItem({required this.id, required this.title, required this.dateTime, this.note = '', this.category = 'Cá nhân', this.remind = true});
  final int id;
  final String title;
  final DateTime dateTime;
  final String note;
  final String category;
  final bool remind;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'dateTime': dateTime.toIso8601String(), 'note': note, 'category': category, 'remind': remind};
  factory CalendarItem.fromJson(Map<String, dynamic> j) => CalendarItem(id: j['id'] as int, title: j['title'] as String, dateTime: DateTime.parse(j['dateTime'] as String), note: (j['note'] ?? '') as String, category: (j['category'] ?? 'Cá nhân') as String, remind: (j['remind'] ?? true) as bool);
}

class SavingGoal {
  SavingGoal({required this.id, required this.name, required this.target, required this.current, required this.deadline});
  final int id;
  final String name;
  final double target;
  final double current;
  final DateTime deadline;
  double get progress => target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble();
  SavingGoal copyWith({double? current}) => SavingGoal(id: id, name: name, target: target, current: current ?? this.current, deadline: deadline);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'target': target, 'current': current, 'deadline': deadline.toIso8601String()};
  factory SavingGoal.fromJson(Map<String, dynamic> j) => SavingGoal(id: j['id'] as int, name: j['name'] as String, target: (j['target'] as num).toDouble(), current: (j['current'] as num).toDouble(), deadline: DateTime.parse(j['deadline'] as String));
}

class ReminderItem {
  ReminderItem({required this.id, required this.title, required this.dateTime, this.note = '', this.done = false, this.enabled = true});
  final int id;
  final String title;
  final DateTime dateTime;
  final String note;
  final bool done;
  final bool enabled;
  ReminderItem copyWith({bool? done, bool? enabled}) => ReminderItem(id: id, title: title, dateTime: dateTime, note: note, done: done ?? this.done, enabled: enabled ?? this.enabled);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'dateTime': dateTime.toIso8601String(), 'note': note, 'done': done, 'enabled': enabled};
  factory ReminderItem.fromJson(Map<String, dynamic> j) => ReminderItem(id: j['id'] as int, title: j['title'] as String, dateTime: DateTime.parse(j['dateTime'] as String), note: (j['note'] ?? '') as String, done: (j['done'] ?? false) as bool, enabled: (j['enabled'] ?? true) as bool);
}
