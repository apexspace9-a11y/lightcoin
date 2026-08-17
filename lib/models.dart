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

  bool get isIncome => type == 'income';

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

const expenseCategories = <String>[
  'Ăn uống',
  'Di chuyển',
  'Mua sắm',
  'Hóa đơn',
  'Nhà ở',
  'Sức khỏe',
  'Giải trí',
  'Giáo dục',
  'Gia đình',
  'Khác',
];

const incomeCategories = <String>[
  'Lương',
  'Thưởng',
  'Kinh doanh',
  'Đầu tư',
  'Quà tặng',
  'Khác',
];
