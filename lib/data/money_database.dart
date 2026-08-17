import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models.dart';

class MoneyDatabase {
  MoneyDatabase._();
  static final MoneyDatabase instance = MoneyDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'save_money.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            occurred_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE goals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target REAL NOT NULL,
            saved REAL NOT NULL DEFAULT 0,
            deadline INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(occurred_at DESC)',
        );
      },
    );
    return _database!;
  }

  Future<List<MoneyTransaction>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'occurred_at DESC, id DESC');
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    final db = await database;
    final data = transaction.toMap()..remove('id');
    final id = await db.insert('transactions', data);
    return MoneyTransaction(
      id: id,
      type: transaction.type,
      amount: transaction.amount,
      category: transaction.category,
      note: transaction.note,
      occurredAt: transaction.occurredAt,
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SavingGoal>> getGoals() async {
    final db = await database;
    final rows = await db.query('goals', orderBy: 'created_at DESC, id DESC');
    return rows.map(SavingGoal.fromMap).toList();
  }

  Future<SavingGoal> addGoal(SavingGoal goal) async {
    final db = await database;
    final data = goal.toMap()..remove('id');
    final id = await db.insert('goals', data);
    return SavingGoal(
      id: id,
      name: goal.name,
      target: goal.target,
      saved: goal.saved,
      deadline: goal.deadline,
      createdAt: goal.createdAt,
    );
  }

  Future<void> updateGoalSaved(int id, double saved) async {
    final db = await database;
    await db.update('goals', {'saved': saved}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('goals');
    });
  }
}
