class CalendarItem {
  CalendarItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.note = '',
    this.category = 'Cá nhân',
    this.remind = true,
  });

  final int id;
  final String title;
  final DateTime dateTime;
  final String note;
  final String category;
  final bool remind;

  CalendarItem copyWith({
    String? title,
    DateTime? dateTime,
    String? note,
    String? category,
    bool? remind,
  }) {
    return CalendarItem(
      id: id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      category: category ?? this.category,
      remind: remind ?? this.remind,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
        'category': category,
        'remind': remind,
      };

  factory CalendarItem.fromJson(Map<String, dynamic> json) => CalendarItem(
        id: json['id'] as int,
        title: json['title'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        note: (json['note'] ?? '') as String,
        category: (json['category'] ?? 'Cá nhân') as String,
        remind: (json['remind'] ?? true) as bool,
      );
}

class SavingGoal {
  SavingGoal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.deadline,
  });

  final int id;
  final String name;
  final double target;
  final double current;
  final DateTime deadline;

  double get progress =>
      target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble();

  SavingGoal copyWith({
    String? name,
    double? target,
    double? current,
    DateTime? deadline,
  }) {
    return SavingGoal(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'current': current,
        'deadline': deadline.toIso8601String(),
      };

  factory SavingGoal.fromJson(Map<String, dynamic> json) => SavingGoal(
        id: json['id'] as int,
        name: json['name'] as String,
        target: (json['target'] as num).toDouble(),
        current: (json['current'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String),
      );
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.note = '',
    this.done = false,
    this.enabled = true,
  });

  final int id;
  final String title;
  final DateTime dateTime;
  final String note;
  final bool done;
  final bool enabled;

  ReminderItem copyWith({
    String? title,
    DateTime? dateTime,
    String? note,
    bool? done,
    bool? enabled,
  }) {
    return ReminderItem(
      id: id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      done: done ?? this.done,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
        'done': done,
        'enabled': enabled,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'] as int,
        title: json['title'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        note: (json['note'] ?? '') as String,
        done: (json['done'] ?? false) as bool,
        enabled: (json['enabled'] ?? true) as bool,
      );
}
