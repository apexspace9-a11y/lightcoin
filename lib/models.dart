class MoneyTransaction {
  const MoneyTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.occurredAt,
  });

  final int? id;
  final String type;
  final double amount;
  final String category;
  final String note;
  final DateTime occurredAt;

  bool get isDeposit => type == 'saving';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isSavingRecord => isDeposit || isWithdrawal;

  int? get goalId {
    if (!category.startsWith('goal:')) return null;
    final raw = category.substring(5).split('|').first;
    return int.tryParse(raw);
  }

  String get goalName {
    if (category == 'free') return 'Quỹ tự do';
    if (!category.startsWith('goal:')) return category;
    final split = category.split('|');
    if (split.length > 1 && split[1].trim().isNotEmpty) return split.sublist(1).join('|');
    return 'Hũ tiết kiệm';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
      };

  factory MoneyTransaction.fromMap(Map<String, Object?> map) => MoneyTransaction(
        id: map['id'] as int?,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        note: (map['note'] as String?) ?? '',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(map['occurred_at'] as int),
      );
}

class SavingGoal {
  const SavingGoal({
    this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.deadline,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double target;
  final double saved;
  final DateTime? deadline;
  final DateTime createdAt;

  double get progress => target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();
  bool get completed => target > 0 && saved >= target;
  double get remaining => (target - saved).clamp(0.0, double.infinity).toDouble();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'deadline': deadline?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory SavingGoal.fromMap(Map<String, Object?> map) => SavingGoal(
        id: map['id'] as int?,
        name: map['name'] as String,
        target: (map['target'] as num).toDouble(),
        saved: (map['saved'] as num).toDouble(),
        deadline: map['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class SavingsChallengeDefinition {
  const SavingsChallengeDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.metric,
  });

  final String id;
  final String title;
  final String subtitle;
  final int target;
  final String metric;
}

const savingsChallenges = <SavingsChallengeDefinition>[
  SavingsChallengeDefinition(
    id: 'seven_days',
    title: '7 ngày tạo đà',
    subtitle: 'Bỏ tiền vào hũ trong 7 ngày khác nhau để tạo nhịp tiết kiệm.',
    target: 7,
    metric: 'days',
  ),
  SavingsChallengeDefinition(
    id: 'twenty_one_days',
    title: '21 ngày thành thói quen',
    subtitle: 'Hoàn thành 21 ngày có tiết kiệm, không cần số tiền lớn.',
    target: 21,
    metric: 'days',
  ),
  SavingsChallengeDefinition(
    id: 'thirty_deposits',
    title: '30 lần bỏ ống',
    subtitle: 'Tích lũy bằng 30 khoản gửi, nhỏ cũng được, miễn là đều.',
    target: 30,
    metric: 'entries',
  ),
  SavingsChallengeDefinition(
    id: 'hundred_deposits',
    title: '100 lần tích lũy',
    subtitle: 'Một thử thách dài hơi cho người muốn biến tiết kiệm thành phản xạ.',
    target: 100,
    metric: 'entries',
  ),
];
